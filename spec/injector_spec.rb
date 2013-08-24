require './injector'

describe Injector do
  class SomeClass; end

  class SomeController
    attr_reader :repository

    def initialize(repository)
      @repository = repository
    end
  end

  class SomeRepository
    attr_reader :db, :relation_name

    def initialize(db, relation_name)
      @db = db
      @relation_name = relation_name
    end
  end

  it 'provides an instance' do
    instance = "hello"
    subject.provides(:hello, instance: instance)

    expect(subject.get(:hello)).to eq(instance)
  end

  it 'provides a Class as an instance' do
    subject.provides(:some_class, instance: SomeClass)

    expect(subject.get(:some_class)).to eq(SomeClass)
  end

  it 'provides instances of a class' do
    subject.provides(:some_instance, class: SomeClass)

    expect(subject.get(:some_instance)).to be_instance_of(SomeClass)
  end

  it 'raises an exception if it doesn\'t find a provider' do
    expect { subject.get(:foo) }.to raise_error(Injector::ProviderNotFound)
  end

  it 'injects constructor dependencies using parameters names' do
    repository = 'a repository'
    subject.provides(:repository, instance: repository)
    subject.provides(:controller, class: SomeController)

    controller = subject.get(:controller)

    expect(controller).to be_instance_of(SomeController)
    expect(controller.repository).to eq(repository)
  end

  it 'injects params recursively' do
    relation_name = 'a relation name'

    subject.provides(:controller, class: SomeController)
    subject.provides(:repository, class: SomeRepository)
    subject.provides(:db, class: SomeClass)
    subject.provides(:relation_name, instance: relation_name)

    controller = subject.get(:controller)

    expect(controller.repository).to be_instance_of(SomeRepository)
    expect(controller.repository.db).to be_instance_of(SomeClass)
    expect(controller.repository.relation_name).to eq(relation_name)
  end

  it 'injects instances of classes in a namespace guessing the class name from the param name' do
    module X; module Y; class Z; end; end; end

    class SomeClass
      attr_reader :z
      def initialize(z)
        @z = z
      end
    end

    subject.provides(:some_class, class: SomeClass)
    subject.provides_namespace(X::Y)

    instance = subject.get(:some_class)

    expect(instance).to be_instance_of(SomeClass)
    expect(instance.z).to be_instance_of(X::Y::Z)
  end
end
