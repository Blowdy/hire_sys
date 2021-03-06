# == Schema Infoamtion
#
# Table name: return_items
#
# id                   :integer(4)  not null, primary key
# hire_item_id         :integer
# sew_return_order_id  :integer
# count                :integer
# return_date          :date
# remark               :string
# pay_state            :string
# total                :integer

class ReturnItem < ActiveRecord::Base
  belongs_to     :sew_return_order
  belongs_to     :hire_item, :counter_cache => true

  validates_presence_of :hire_item_id,  :message => "空退车记录！"
  validates_presence_of :count,         :message => "请填写退车数量"
  validates_presence_of :return_date,   :message => "请填写实际退车日期"

  validate_on_create :valid_count
  before_save :save_state_cn
  before_save :save_total

  state_machine :pay_state, :initial => :unpaid do
    before_transition :unpaid => :paid, :do => :validates_order_approve_state
    before_transition :unpaid => :cancel, :do => :validates_order_cancel_state
    event(:pay) { transition [:unpaid,:paid] => :paid }
    event(:cancel) { transition [:unpaid] => :cancel }
  end

  PayStateCn = {
    "unpaid" => "未付款",
    "paid" => "已付款",
    "cancel" => "取消付款"
  }

  def self.states_for_query
    rs = []
    PayStateCn.each { |k, v| rs << { :value => v } }
    rs
  end

  def actual_hire_date
    hire_item.actual_hire_date == nil ? " " : hire_item.actual_hire_date
  end

  def return_count
    count
  end

  def order_approed?
    sew_return_order.state == "approved"
  end

  def order_cancel?
    sew_return_order.state == "cancel"
  end

  def sew_hire_order_id
    hire_item.sew_hire_order_id
  end

  def department
    sew_return_order.department.name
  end

  def garage
    hire_item.garage
  end
  
  def return_order_state
    sew_return_order.state_cn
  end
  def return_person
    sew_return_order.return_person
  end
  def sew_dealer
    sew_return_order.sew_dealer
  end
  
  def sew_name
    self.hire_item == nil ? "" : self.hire_item.sew_name
  end

  def cloth_number
    self.hire_item == nil ? "" : self.hire_item.cloth_number
  end

  def retain_count
    self.hire_item == nil ? "" : self.hire_item.retain_count
  end

  def hire_date
    self.hire_item == nil ? "" : self.hire_item.hire_date
  end

  def expect_return_date
    self.hire_item == nil ? "" : self.hire_item.expect_return_date
  end

  def price
    self.hire_item.price == nil ? "0" : self.hire_item.price
  end

  def total_price
    #h_date = self.actual_hire_date.to_s
    h_date = self.hire_date.to_s
    r_date = self.return_date.to_s
    price  = self.price
    count  = self.count
    day_count = DateTime.parse(r_date)-DateTime.parse(h_date)
    total_price = day_count.to_i * price.to_i * count
  end

  def save_state_cn
    state_cn_become = PayStateCn[self.pay_state]
    self.state_cn = state_cn_become 
  end


  private

    def save_total 
      total_price = self.total_price
      self.total  = total_price
    end
    def valid_count 
      if self.count > self.retain_count
        errors.add_to_base( "退车数量不能大于可退车数！" )
      end
      true
    end
    def validates_order_approve_state
      if order_approed?
        return true
      end
      errors.add_to_base( "progress","订单未通过批复不能进行付款操作" )
      return false
    end
    def validates_order_cancel_state
      if order_cancel?
        return true
      end
      errors.add_to_base( "progress","订单未取消不能取消付款" )
      return false
    end

end
