class Backend::DrupalInfoController < Backend::BackendController
  def invalid_subs
    @active_invalid = []
    BoxSubscription.where(active: true).find_in_batches(batch_size: 100) do |batch|
      @active_invalid << batch.select(&:invalid?)
    end

    @cancelled_invalid_with_box_count = []
    BoxSubscription.where(status: 'cancelled').where('box_count > 0').find_in_batches(batch_size: 100) do |batch|
      @cancelled_invalid_with_box_count << batch.select(&:invalid?)
    end

    @active_invalid.flatten!
    @cancelled_invalid_with_box_count.flatten!
  end

  def invalid_users
    @invalid_users = []
    User.find_in_batches(batch_size: 1000) do |batch|
      @invalid_users << batch.select(&:invalid?)
    end
    @invalid_users.flatten!
  end

end
