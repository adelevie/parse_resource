class ParseUserValidator < ActiveModel::Validator
  def validate(record)
    @user = User.where(:username => record.username)
    if @user.length > 0
      record.errors[:username] << "is already taken."
    end
  end
end