require 'parse_resource'
require 'pp'


ParseResource.load!("FKEzdzDgEyghLDFgIVHYJehVlWpfVtUmEv4MUEkJ", "bOYO7usWbrcIbL5L5bPzlYrSonQRvwJecC1XLsuN")

class Post < ParseResource
  fields :title, :author, :body

  after_save :add_author

  def add_author
    update(:author => "Alan")
  end
end
