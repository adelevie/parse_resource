class ParseRole < ParseResource::Base
  fields :name, :users, :roles

  def name
    val = get_attribute("name")
  end

  def users
    val = User.related_to(self, :users)
  end
end
