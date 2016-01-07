class ParseUserValidator < ActiveModel::Validator
  # Make a request to Parse and find any users with same username
  # If a record exists add an error to User model
  def validate(record)
    if User.where(username: record.username).any?
      record.errors.add :username, "is already taken."
    end
  end
end