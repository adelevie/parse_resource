class Children
  attr_reader :array
  
  def initialize(array)
    @array = array
  end
  
  class << @array
    def <<(child)
      #do something
      super(val)
    end
  end
  
  def <<(child)
    @array << child
    @array
  end
  
  def method_missing(meth, *args, &block)
    if Array.method_defined?(meth)
      all.send(meth, *args, &block)
    else
      super
    end
  end

  def respond_to?(meth)
    if Array.method_defined?(meth)
      true
    else
      super
    end
  end
  
end