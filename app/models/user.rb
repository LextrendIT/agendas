class User < ActiveRecord::Base

  # Relations
  has_many :events
  has_many :manages, dependent: :destroy
  has_many :holders, through: :manages

  accepts_nested_attributes_for :manages, :reject_if => :all_blank, :allow_destroy => true


  # Validations
  validates_presence_of :first_name, :last_name, :email
  validate :manages_uniqueness

  enum role: [:user, :admin]
  after_initialize :set_default_role, if: :new_record?
  after_initialize :set_active, if: :new_record?


  scope :active, -> {where(:active => true)}

  def name
    last_name.to_s + ", " + first_name.to_s
  end

  def full_name
    (self.first_name+' '+self.last_name).mb_chars.to_s
  end

  def full_name_comma
    (self.last_name.to_s+', '+self.first_name.to_s).mb_chars.to_s
  end

  def manages_uniqueness
    manages = self.manages.reject(&:marked_for_destruction?)
    errors.add(:base, I18n.t('backend.participants_uniqueness')) unless manages.map{|x| x.holder_id}.uniq.count == manages.to_a.count
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  private

  def set_active
    self.active ||= true
  end

  def set_default_role
    self.role ||= :user
  end

  def self.create_from_uweb(role, data)
    user = User.find_or_initialize_by(user_key: data['CLAVE_IND'])
    user.first_name = data["NOMBRE_USUARIO"].strip
    user.last_name = data["APELLIDO1_USUARIO"].strip
    user.last_name += ' ' + data["APELLIDO2_USUARIO"].strip if data["APELLIDO2_USUARIO"].present?
    user.email =  data["MAIL"].blank? ? Faker::Internet.email : data["MAIL"]
    user.password = SecureRandom.uuid
    user.role = role
    user
  end

end
