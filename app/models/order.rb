class Order < ApplicationRecord
    belongs_to :user

    validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :quantity, presence: true, numericality: { greater_than: 0 }
    validates :order_type, presence: true, inclusion: { in: ['buy', 'sell'] }
    validates :status, presence: true, inclusion: { in: ['pending', 'completed', 'canceled'] }


    scope :completed_buy_orders, -> { where(order_type: :buy, status: :completed) }
    scope :completed_for_user, ->(user_id) { joins(:user).where(users: { id: user_id })
                                                        .where(status: :completed)
                                                        .sum(:quantity)
    }

    def self.process_order(order, sell_threshold, buy_threshold)
        begin
          if order.buy? && order.price < buy_threshold
            order.update(status: :completed)
          elsif order.sell? && order.price > sell_threshold
            order.update(status: :completed)
          else
            order.update(status: :canceled)
          end
        rescue => e
          Rails.logger.error "Error processing order: #{e.message}"
        end
    end

    def buy?
        order_type == 'buy'
    end

    def sell?
        order_type == 'sell'
    end
end
