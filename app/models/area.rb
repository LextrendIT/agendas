class Area < ActiveRecord::Base

  has_ancestry

  # Relations
  belongs_to :parent, class_name: "Area", foreign_key: "parent_id"
  has_many :children, class_name: "Area", foreign_key: "parent_id", dependent: :destroy

  # Validations
  validates_presence_of :title

  # Callbacks
  before_create :set_defaults
  after_save :update_children

  def self.area_tree
    all.each { |c| c.ancestry = c.ancestry.to_s + (c.ancestry != nil ? "/" : '') + c.id.to_s
    }.sort {|x,y| x.ancestry <=> y.ancestry
    }.map{ |c| ["--"  * (c.depth - 1) + c.title,c.id]
    }
  end

  private

  def set_defaults
    self.active ||= true
  end

  def update_children
    self.children.update_all active: self.active unless self.active == self.active_was
  end

end
