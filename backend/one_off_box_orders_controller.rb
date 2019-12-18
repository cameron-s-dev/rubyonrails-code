class Backend::OneOffBoxOrdersController < Backend::BackendController

  after_action :verify_authorized

  def index

    if params[:query].present?
      @one_off_box_orders = apply_scopes(policy_scope(::OneOffBoxOrder)).search_for_order(params[:query]).order(:date).page(params[:page]).per(params[:per_page] || 100)
    else
      @one_off_box_orders = apply_scopes(policy_scope(::OneOffBoxOrder)).page(params[:page]).order(:date).per(params[:per_page] || 100)
    end

    authorize @one_off_box_orders
  end

  def show
    @one_off_box_orders = OneOffBoxOrder.where(snipcart_order_id: params[:id])

    setup_snipcart_details

    @user = @one_off_box_orders.first.user

    authorize @one_off_box_orders
  end

  def edit
    snipcart_order_id = params[:id]

    @one_off_box_orders = OneOffBoxOrder.where(snipcart_order_id: params[:id])

    setup_snipcart_details

    authorize @one_off_box_orders
  end

  def update
    snipcart_order_id = params[:id]

    @one_off_box_orders = OneOffBoxOrder.where(snipcart_order_id: params[:id])

    OneOffBoxOrder.transaction do
      @one_off_box_orders.each do |one_off_box_order|
        one_off_box_order.update_attributes! permitted_params.one_off_box_order
      end
    end

    redirect_to backend_one_off_box_order_path(snipcart_order_id), notice: 'Updated...'

    authorize @one_off_box_orders
  end

  def shipit
    # consider use sidekiq to do the job
    snipcart_order_id = params[:id]

    @one_off_box_orders = OneOffBoxOrder.where(snipcart_order_id: params[:id], tracking_state: nil, processing_error: nil)

    @one_off_box_orders.each do |one_off_box_order|
      delivery_details = build_delivery_details one_off_box_order, snipcart_order_id

      if one_off_box_order.box.one_offs_inventory_sold_out?

        one_off_box_order.processing_error = "Not enough inventory"
        one_off_box_order.save

        next
      end

      if !has_valid_delivery_address?(delivery_details)

        one_off_box_order.processing_error = "Invalid address"
        one_off_box_order.save

        next
      end

      client = Shippit::Api::Client.new

      resp = client.send_order delivery_details

      if resp.fetch(:success, false)
        one_off_box_order.update_attributes(
          tracking_state: parse_shippit_status(resp.fetch(:data).fetch("state", "")),
          tracking_number: resp.fetch(:data).fetch("tracking_number", "")
        )
      else
        one_off_box_order.processing_error = "Problem sending to dispatcher (Shippit)"
        one_off_box_order.save
      end
    end

    authorize @one_off_box_orders
    redirect_to backend_one_off_box_order_path(snipcart_order_id), notice: 'See results below'
  end

  private

  def setup_snipcart_details

    @snipcart = OpenStruct.new
    @snipcart.id = params[:id]

    first_box_item = @one_off_box_orders.first

    @snipcart.email = first_box_item.snipcart_user_email
    @snipcart.invoice_number = first_box_item.snipcart_invoice_number
    @snipcart.date = first_box_item.date.to_date

    @snipcart.shipping_address_address1 = first_box_item.shipping_address_address1
    @snipcart.shipping_address_address2 = first_box_item.shipping_address_address2
    @snipcart.shipping_address_postal_code = first_box_item.shipping_address_postal_code
    @snipcart.shipping_address_city = first_box_item.shipping_address_city
    @snipcart.shipping_address_province = first_box_item.shipping_address_province
    @snipcart.shipping_address_full_name = first_box_item.shipping_address_full_name
    @snipcart.shipping_address_name = first_box_item.shipping_address_name
    @snipcart.shipping_address_phone = first_box_item.shipping_address_phone
  end

  def parse_shippit_status status
    return 'delivery_processing' if status == 'processing'
    return 'delivery_failed'
  end

  def build_delivery_details(one_off_box_order, snipcart_order_id)

    user = one_off_box_order.user

    delivery_details = {
      order:  {
        user_attributes: {
          email: user.try(:email) || one_off_box_order.snipcart_user_email,
          first_name: user.try(:first_name) || one_off_box_order.shipping_address_full_name,
          last_name: user.try(:last_name) || one_off_box_order.shipping_address_name
        },
        parcel_attributes: parcel_attributes(one_off_box_order.snipcart_item_quantity),
        courier_type: "standard",
        delivery_postcode: one_off_box_order.shipping_address_postal_code,
        delivery_address: "#{one_off_box_order.shipping_address_address1} #{one_off_box_order.shipping_address_address2}",
        delivery_suburb: one_off_box_order.shipping_address_city,
        delivery_state: one_off_box_order.shipping_address_province,
        delivery_instructions: nil,
        receiver_name: one_off_box_order.shipping_address_full_name,
        receiver_contact_number: (one_off_box_order.shipping_address_phone unless !user.try(:track_via_sms?)),
        retailer_invoice: "#{one_off_box_order.box.identifier}",
      }
    }
  end

  def parcel_attributes(item_quantity)
    [
      {
        qty: item_quantity,
        length: 0.31,
        width: 0.22,
        depth: 0.11,
        weight: 1.0
      }
    ]
  end

  def has_valid_delivery_address?(delivery_details)

    p = Postcode.arel_table
    Postcode.where(p[:state].matches(delivery_details[:order][:delivery_state])).
      where(p[:code].matches(delivery_details[:order][:delivery_postcode])).
      where(p[:suburb].matches(delivery_details[:order][:delivery_suburb]))
  end
end
