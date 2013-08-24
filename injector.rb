class Injector
  class ProviderNotFound < Exception; end

  def initialize
    @providers = {}
  end

  def provides(name, options)
    @providers[name.to_sym] = Provider.from_options(options, self)
  end

  def provides_namespace(namespace)
    @providers[:z] = NamespaceProvider.new(namespace, self)
  end

  def get(name)
    return @providers[name].get if @providers.has_key?(name)
    raise ProviderNotFound
  end
end

class Provider
  def self.from_options(options, injector)
    return InstanceProvider.new(options[:instance]) if options[:instance]
    return ClassProvider.new(options[:class], injector) if options[:class]
  end
end

class InstanceProvider < Provider
  def initialize(instance)
    @instance = instance
  end

  def get
    @instance
  end
end

class ClassProvider < Provider
  def initialize(klass, injector)
    @klass = klass
    @injector = injector
  end

  def get
    constructor = @klass.instance_method(:initialize)
    constructor_param_names = constructor.parameters.map(&:last)
    constructor_params = constructor_param_names.map { |param_name| @injector.get(param_name) }
    @klass.new(*constructor_params)
  end
end

class NamespaceProvider < ClassProvider
  def initialize(namespace, injector)
    @namespace = namespace
    @injector = injector
  end

  def get
    name = :z
    klass_name = name.to_s.split('_').map(&:capitalize).join
    @klass = @namespace.const_get(klass_name)
    super
  end
end
