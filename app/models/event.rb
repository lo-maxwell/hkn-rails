class Event < ActiveRecord::Base

  # === List of columns ===
  #   id                       : integer 
  #   name                     : string 
  #   slug                     : string 
  #   location                 : string 
  #   description              : text 
  #   start_time               : datetime 
  #   end_time                 : datetime 
  #   created_at               : datetime 
  #   updated_at               : datetime 
  #   event_type_id            : integer 
  #   need_transportation      : boolean 
  #   view_permission_group_id : integer 
  #   rsvp_permission_group_id : integer 
  # =======================

  has_many :blocks, :dependent => :destroy
  has_many :rsvps, :dependent => :destroy
  belongs_to :event_type
  belongs_to :view_permission_group, { :class_name => "Group" }
  belongs_to :rsvp_permission_group, { :class_name => "Group" }
  validates :name, :presence => true
  validates :location, :presence => true
  validates :description, :presence => true
  validates :event_type, :presence => true
  validate :valid_time_range

  scope :past,     joins(:event_type).where(['start_time < ?', Time.now])
  scope :upcoming, joins(:event_type).where(['start_time > ?', Time.now])
  scope :all,      joins(:event_type)
  scope :current,  joins(:event_type).where(['start_time > ? AND start_time < ?', Property.semester_start_time, Time.now])

  scope :with_permission, Proc.new { |user| 
    if user.nil?
      where(:view_permission_group_id => nil)
    else
      where('view_permission_group_id IN (?) OR view_permission_group_id IS NULL', user.groups.map{|group| group.id})
    end
  }

  VALID_SORT_FIELDS = %w[start_time name location event_type]

  # Note on slugs: http://googlewebmastercentral.blogspot.com/2009/02/specify-your-canonical.html 
  
  def self.upcoming_events(num, user=nil)
    self.with_permission(user).find(:all, :conditions => ['end_time >= ? AND end_time <= ?',
    Time.now, Time.now + 7.days], :order => "start_time asc", :limit => num)
    
  end
  
  def valid_time_range
    if !start_time.blank? and !end_time.blank?
      errors[:end_time] << "must be after start time" unless start_time < end_time
    end
  end

  def short_start_time
    ampm = (start_time.hour >= 12) ? "p" : "a"
    min = (start_time.min > 0) ? start_time.strftime('%M') : ""
    hour = start_time.hour
    if hour > 12
      hour -= 12
    elsif hour == 0
      hour = 12
    end
    "#{hour}#{min}#{ampm}"
  end

  def start_date
    start_time.strftime('%Y %m/%d')
  end

  def nice_time_range
    if start_time.to_date == end_time.to_date 
      "#{start_time.strftime('%a %m/%d %I:%M%p')} - #{end_time.strftime('%I:%M%p')}"
    else 
      "#{start_time.strftime('%a %m/%d %I:%M%p')} - #{end_time.strftime('%a %m/%d %I:%M%p')}"
    end 
  end

  def can_view? user
    if user.nil?
      view_permission_group.nil?
    else
      view_permission_group.nil? or user.groups.include? view_permission_group
    end
  end

  def allows_rsvps?
    not blocks.empty?
  end

  # can_rsvp? only checks permission categories, not whether rsvps are enabled
  def can_rsvp? user
    if user.nil?
      false
    else
      user.groups.include? rsvp_permission_group
    end
  end

  # Notifies all people who want to receive event alerts
  def rsvp_notify_people!
    message = "#{name} starts at #{short_start_time}. Meet at #{location}! To unsubscribe, email ops@hkn.eecs.berkeley.edu"
    rsvps.each do |rsvp|
      rsvp.person.send_sms! message
    end
  end

end
