class String
  #
  # Convert from camel case to snake case
  #
  #     'FooBar'.snake_case # => "foo_bar"
  #

  def snake_case
    gsub(/\B[A-Z][^A-Z]/, '_\&').downcase.gsub(' ', '_')
  end
  
  #
  # Convert from snake case to camel case
  #
  #     'foo_bar'.snake_case # => "FooBar"
  #

  def camel_case
   split('_').map{|e| e.capitalize}.join
  end
  
  
  #
  # A convenient way to do File.join
  #
  #   'a' / 'b' # => 'a/b'
  #

  def / obj
    File.join(self, obj.to_s)
  end
end