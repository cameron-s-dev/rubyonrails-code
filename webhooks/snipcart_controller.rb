class Webhooks::SnipcartController < ApplicationController

  include SnipcartOrder

  skip_before_filter :verify_authenticity_token

  def webhook
    begin
      data = ActiveSupport::JSON.decode(request.body.read)
      case data["eventName"]
      when 'order.completed'
        snipcart_order_id = data['content']['token']

        # # GA Ecommerce Tracking

        # tracker = Staccato.tracker('UA-50664216-1')

        # transaction_id = SecureRandom.hex

        # # Track transaction 
        # tracker.transaction({
        #   transaction_id: transaction_id,
        #   affiliation: 'snipcart',
        #   revenue: data['content']['itemsTotal'],
        #   shipping: 0.00,
        #   tax: data['content']['taxesTotal'],
        # })

        # # Track transaction items
        # data['content']['items'].map do |item|
        #   tracker.transaction_item({
        #     transaction_id: transaction_id,
        #     name: item['name'],
        #     price: item['price'],
        #     quantity: item['quantity'],
        #     sku: item['uniqueId'],
        #     category: 'One Off Box',
        #   })
        # end

        download_order(snipcart_order_id) unless OneOffBoxOrder.exists?(snipcart_order_id: snipcart_order_id)
      end
    rescue => e

      logger.error "Snipcart webhook failed : #{e}"

      # if this failed then we need to trigger the webhook manually via changing the status of the order in Snipcart dashboard

      # When something goes wrong, return an invalid status code
      # such as 400 BadRequest.
      Raven.capture_exception(e)
      head :bad_request
    else
      # Return a valid status code such as 200 OK.
      head :ok
    end
  end

  private

  # download the order details from GMB since Snipcart's call to our webhook is unauthenticated
  def download_order(snipcart_order_id)

    snipcart_order = get_snipcart_order snipcart_order_id

    snipcart_user_id = snipcart_order['user']['id']

    snipcart_user_email = snipcart_order['user']['email']
    user = User.where(email: snipcart_user_email).take

    snipcart_creation_date = DateTime.parse(snipcart_order['creationDate'])
    snipcart_invoice_number = snipcart_order['invoiceNumber']

    shipping_address = snipcart_order['shippingAddress']

    # each snipcart_order could have multiple boxes
    OneOffBoxOrder.transaction do

      snipcart_order['items'].map do |item|

        box = Box.find item['id']

        OneOffBoxOrder.create!(
          user: user,
          box: box,
          date: snipcart_creation_date,
          snipcart_order_id: snipcart_order_id,
          snipcart_user_id: snipcart_user_id,
          snipcart_user_email: snipcart_user_email,
          snipcart_invoice_number: snipcart_invoice_number,
          snipcart_item_quantity: item['quantity'],
          snipcart_item_total: item['totalPrice'],
          shipping_address_address1: shipping_address['address1'],
          shipping_address_address2: shipping_address['address2'],
          shipping_address_postal_code: shipping_address['postalCode'],
          shipping_address_city: shipping_address['city'],
          shipping_address_province: shipping_address['province'],
          shipping_address_full_name: shipping_address['fullName'],
          shipping_address_name: shipping_address['name'],
          shipping_address_phone: shipping_address['phone']
        )
      end
    end

  end
end
