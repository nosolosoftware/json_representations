# JsonRepresentations
[![Gem Version](https://badge.fury.io/rb/json_representations.svg)](https://badge.fury.io/rb/json_representations)
![Build Status](https://github.com/nosolosoftware/json_representations/actions/workflows/rspec.yml/badge.svg)

Creates representations of your model data in a simple and clean way.

## Features

* Easy to use
* Easy to define representations
* Support representations hinheritance
* Support module definition
* Support options
* Support ActiveRecord collection options
* Faster

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_representations'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json_representations

## Usage

Includes the `JsonRepresentations` module into your class and define your representations.
Representations are evaluated into class instance object and must returns a `json` object.

```ruby
class User
  include JsonRepresentations

  attr_accessor :first_name, :last_name, :age, :city

  def initialize(first_name, last_name, age, city)
    @first_name = first_name
    @last_name = last_name
    @age = age
    @city = city
  end

  representation :public do |options| # you can pass options
    {
      full_name: "#{first_name} #{last_name}",
      date: options[:date]
    }
  end

  representation :private, extend: :public do # you can extends another representations
    {
      age: age,
      city: city.representation(:basic)
    }
  end
end

# you can define representations in a module
module CityRepresentations
  include JsonRepresentations

  representation :basic do
    {
      name: name
    }
  end
end

class City
  include CityRepresentations

  attr_accessor :name

  def initialize(name)
    @name = name
  end
end

city = City.new('Madrid')
user = User.new('John', 'Doe', 30, city)

user.representation(:private, date: '2017-12-21')
# {:full_name=>"John Doe", :date=>"2017-12-21", :age=>30, :city=>{:name=>"Madrid"}}

user.representation(:private, date: '2017-12-21') # short form
# {:full_name=>"John Doe", :date=>"2017-12-21", :age=>30, :city=>{:name=>"Madrid"}}
```

## Modules Inheritance

You can include a module representation into other module like this example:

```ruby
module ParentRepresentations
  include JsonRepresentations

  representation :a do {name: name} end
  representation :b do {name: name} end
  representation :c do {name: name} end
end

module ChildRepresentations
  include ParentRepresentations

  representation :a do # overwrite
    {color: color}
  end

  representation :b, extend: true do # extend parent representation with same name
    {color: color}
  end

  representation :d, extend: :c do # extend parent representation
    {color: color}
  end
end

class Child
  include ChildRepresentations

  attr_accessor :color

  def initialize(name, color)
    @name = name
    @color = color
  end
end

child = Child.new('child', 'red')
child.representation(:a) # {color: 'red'}
child.representation(:b) # {name: 'child', color: 'red'}
child.representation(:c) # {name: 'child'}
child.representation(:d) # {name: 'child', color: 'red'}
```

When you includes representation module (parent) into other module (child):

* Parent representations are included
* If a representation is redefined, it is overwritten
* You can extend parent representations
* You must use `extend: true` when use the same name

## ActiveRecord collection options

You can use this ActiveRecord option when you define a representation:

* [includes](https://apidock.com/rails/ActiveRecord/QueryMethods/includes)
* [eager_load](https://apidock.com/rails/ActiveRecord/QueryMethods/eager_load)
* [preload](https://apidock.com/rails/ActiveRecord/QueryMethods/preload)

```
representation :private, includes: [:city]
  {
    age: age,
    city: city.representation(:basic)
  }
end
```

This options will be used on the collection before to serializing it automatically.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nosolosoftware/json_representations.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
