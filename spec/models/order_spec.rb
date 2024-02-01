require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:user) { User.create(name: 'Vitalii') }

  describe 'completed_buy_orders scope' do
    let(:completed_buy_order) { Order.create(order_type: :buy, status: :completed, quantity: 1, price: 2.2, user: user) }
    let(:completed_sell_order) { Order.create(order_type: :sell, status: :completed, quantity: 1, price: 2.2, user: user) }
    let(:pending_buy_order) { Order.create(order_type: :buy, status: :pending, quantity: 1, price: 2.2, user: user) }

    it 'returns only completed buy orders' do
      expect(Order.completed_buy_orders).to include(completed_buy_order)
      expect(Order.completed_buy_orders).not_to include(completed_sell_order)
      expect(Order.completed_buy_orders).not_to include(pending_buy_order)
    end
  end

  describe '.process_order' do
    context 'when order is a buy order' do
      let(:order) { Order.create(order_type: :buy, status: :pending, quantity: 1, price: 90, user: user)}

      it 'marks the order as completed if price is below buy threshold' do
        Order.process_order(order, 100, 200)
        expect(order.reload.status).to eq('completed')
      end

      it 'marks the order as canceled if price is equal to or above buy threshold' do
        Order.process_order(order, 80, 80)
        expect(order.reload.status).to eq('canceled')
      end
    end

    context 'when order is a sell order' do
      let(:order) { Order.create(order_type: :sell, status: :pending, quantity: 1, price: 210, user: user) }

      it 'marks the order as completed if price is above sell threshold' do
        Order.process_order(order, 100, 200)
        expect(order.reload.status).to eq('completed')
      end

      it 'marks the order as canceled if price is equal to or below sell threshold' do
        Order.process_order(order, 230, 220)
        expect(order.reload.status).to eq('canceled')
      end
    end

    it 'handles exceptions and logs appropriate errors' do
      allow_any_instance_of(Order).to receive(:update).and_raise(StandardError)
      expect(Rails.logger).to receive(:error).with(/Error processing order:/)
      
      # Instead of using build_stubbed, create a real Order instance
      order = Order.new(order_type: :buy, status: :pending, quantity: 1, price: 90, user: user)
      Order.process_order(order, 100, 200)
    end
  end
end
