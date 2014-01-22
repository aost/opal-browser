BROWSER_ENGINE = `/MSIE|WebKit|Presto|Gecko/.exec(navigator.userAgent)[0]`.downcase rescue :unknown

module Browser

module Compatibility
  # FIXME: v
  # def self.respond_to?(parent = `window`, object, method)
  # ^
  def self.respond_to?(*args)
    if args.length == 2
      parent         = `window`
      object, method = args
    else
      parent, object, method = args
    end

    %x{
      if (!#{parent}) {
        return false;
      }

      var klass = #{parent}[#{object}];

      if (!klass) {
        return false;
      }

      return typeof(klass.prototype[#{method}]) === "function";
    }
  end

  # FIXME: v
  # def self.has?(parent = `window`, name)
  # ^
  def self.has?(*args)
    if args.length == 1
      parent = `window`
      name,  = args
    else
      parent, name = args
    end

    %x{
      if (!#{parent}) {
        return false;
      }

      return #{parent}[#{name}] != null;
    }
  end

  def self.xpath?
    defined? `document.evaluate`
  end

  def self.css?
    respond_to? :Element, :querySelectorAll
  end

  def self.sizzle?
    defined? `window.Sizzle`
  end

  def self.wgxpath?
    defined? `window.wgxpath`
  end

  def self.new_event?
    %x{
      try {
        new Event("x");

        return true;
      }
      catch (e) {
        return false;
      }
    }
  end

  def self.create_event?
    has? `document`, :createEvent
  end

  def self.create_event_object?
    has? `document`, :createEventObject
  end

  def self.attach_event?
    has? `document`, :attachEvent
  end

  def self.detach_event?
    has? `document`, :detachEvent
  end

  def self.fire_event?
    has? `document`, :fireEvent
  end

  def self.immediate?(prefix = nil)
    if prefix
      has?("#{prefix}SetImmediate")
    else
      has?(:setImmediate)
    end
  end

  def self.post_message?
    return false unless has?(:postMessage) && !has?(:importScripts)

    %x{
      var ok  = true,
          old = window.onmessage;

      window.onmessage = function() { ok = false; };
      window.postMessage("", "*")
      window.onmessage = old;

      return ok;
    }
  end

  def self.ready_state_change?
    `"onreadystatechange" in window.document.createElement("script")`
  end

  def self.local_storage?
    has? :localStorage
  end

  def self.global_storage?
    has? :globalStorage
  end

  def self.add_behavior?
    has? `document.body`, :addBehavior
  end
end

C = Compatibility

end
