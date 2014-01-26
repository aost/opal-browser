class Browser::WebGLCanvas < Native::Object
  def initialize(element)
    @native = `#{element.to_n}.getContext('experimental-webgl')`

    self
  end
end
