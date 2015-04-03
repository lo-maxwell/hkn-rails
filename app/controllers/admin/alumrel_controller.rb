class Admin::AlumrelController < Admin::AdminController
  before_filter :authorize_alumrel

  def index
  end

  def graduations
    @graduating = Person.where("people.graduation IS NOT NULL")
    @graduating = @graduating.sort_by{|p| Property.parse_semester(p.graduation)}.reverse
  end
end
