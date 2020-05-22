# SequelPlugins
[![Build Status](https://travis-ci.org/umbrellio/umbrellio-sequel-plugins.svg?branch=master)](https://travis-ci.org/umbrellio/umbrellio-sequel-plugins)
[![Coverage Status](https://coveralls.io/repos/github/umbrellio/umbrellio-sequel-plugins/badge.svg?branch=master)](https://coveralls.io/github/umbrellio/umbrellio-sequel-plugins?branch=master)
[![Gem Version](https://badge.fury.io/rb/umbrellio-sequel-plugins.svg)](https://badge.fury.io/rb/umbrellio-sequel-plugins)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'umbrellio-sequel-plugins'
```

And then execute:

    $ bundle

# Extensions

- `CurrencyRates`
- `PGTools`
- `Slave`
- `Synchronize`
- `methods_in_migrations`
- `deferrable_foreign_keys`

# Plugins

- `Duplicate`
- `GetColumnValue`
- `MoneyAccessors`
- `StoreAccessors`
- `Synchronize`
- `Upsert`
- `WithLock`

# Tools
- `TimestampMigratorUndoExtension`

## CurrencyRates

Plugin for joining currency rates table to any other table and money exchange.

Enable: `DB.extension :currency_rates`

Currency rates table example:

```sql
CREATE TABLE currency_rates (
    id integer NOT NULL,
    currency text NOT NULL,
    period tsrange NOT NULL,
    rates jsonb NOT NULL
);

INSERT INTO currency_rates (currency, period, rates) VALUES
('EUR', tsrange('2019-02-07 16:00:00 +0300', '2019-02-07 16:00:00 +0300'), '{"USD": 1.1, "EUR": 1.0, "RUB": 81}'),
('EUR', tsrange('2019-02-07 17:00:00 +0300', NULL), '{"USD": 1.2, "EUR": 1.0, "RUB": 75}')
```

Usage example:

```sql
CREATE TABLE items (
    id integer NOT NULL,
    currency text NOT NULL,
    price numeric NOT NULL,
    created_at timestamp without time zone NOT NULL
);

INSERT INTO items (currency, price, created_at) VALUES ("EUR", 10, '2019-02-07 16:10:00 +0300')
```

```ruby
DB[:items]
    .with_rates
    .select(Sequel[:price].exchange_to("USD").as(:usd_price))
    .first
# => { "usd_price" => 12.0 }
```


## PGTools

Enable: `DB.extension :pg_tools`

### `#inherited_tables_for`

Plugins for getting all inherited tables.

Example:

```ruby
DB.inherited_tables_for(:event_log) # => [:event_log_2019_01, :event_log_2019_02]
```

## Slave

Enable: `DB.extension :slave`

Plugin for choosing slave server for query.

Example:

```ruby
DB[:users].slave.where(email: "test@test.com") # executes on a slave server
```

**Important:** you have to define a server named 'slave' in sequel config before using it.


## Synchronize

Enable: `DB.extension :synchronize`

Plugin for using transaction advisory locks for application-level mutexes.

Example:

```ruby
DB.synchronize_with([:ruby, :forever]) { p "Hey, I'm in transaction!"; sleep 5 }
# => BEGIN
# => SELECT pg_try_advisory_xact_lock(3764656399) -- 'ruby-forever'
# => COMMIT
```

## Methods in Migrations

Enable: `Sequel.extension(:methods_in_migrations)`

Support for method definitions and invocations inside `Sequel.migration`.

Example:

```ruby
Sequel.extension(:methods_in_migrations)

Sequel.migration do
  # define
  def get_data
    # ...some code...
  end

  # use
  up { get_data }
  down { get_data }

  # without extension:
  #   => NameError: undefined local variable or method `get_data' for #<Sequel::Postgres::Database>
end
```

## Deferrable Foreign Keys

Enable: `Sequel.extension(:deferrable_foreign_keys)`

Makes foreign keys constraints deferrable (`DEFERABLE INITIALLY DEFERRED`) by default.

Example:

```ruby
DB.create_table(:users) { primary_key :id }
DB.create_table(:items) do
  primary_key :id
  foreign_key :user_id, :users
end
```
```sql
CREATE TABLE users (
  id integer NOT NULL
);
CREATE TABLE items (
  id integer NOT NULL
);

-- without extension:
ALTER TABLE items ADD CONSTRAINT items_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);

-- with extension:
ALTER TABLE items ADD CONSTRAINT items_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) DEFERRABLE INITIALLY DEFERRED;
```

OR

```ruby
# wives attributes: id (pk), husband_id (fk)
# husbands attributes: id (pk), wife_id (fk)
 
Wife = Sequel::Model(:wives)
Husband = Sequel::Model(:husbands)

DB.transaction do
  wife = Wife.create(id: 1, husband_id: 123456789)
  husband = Husband.create(id: 1)
  wife.update(husband_id: husband.id)
  husband.update(wife_id: wife.id)
end
# assume there are no husband with id=123456789
# without extension:
#   => Sequel::ForeignKeyConstraintViolation: Key (husband_id)=(123456789) is not present in table "husbands".
# with extension:
#   => <Wife @attributes={id:1, husband_id: 1}>
#   => <Husband @attributes={id:1, wife_id: 1}>
```

## Duplicate

Enable: `Sequel::Model.plugin :duplicate`

Model plugin for creating a copies.

Example:

```ruby
User = Sequel::Model(:users)
user1 = User.create(name: "John")
user2 = user1.duplicate(name: "James")
user2.name # => "James"
```
OR

```ruby
user2 = User.duplicate(user1, name: "James")
user2.name # => "James"
```

## GetColumnValue

Enable: `Sequel::Model.plugin :get_column_value`

Plugin for getting raw column value

Example:

```ruby
item = Item.first
item.price # => #<Money fractional:5000.0 currency:USD>
item.get_column_value(:amount) # => 0.5e2
```

## MoneyAccessors

**Important:** requires `money` gem described below.

Plugin for using money field keys as model properties.

Enable:

```ruby
gem "money"
Sequel::Model.plugin :money_accessors
````

Examples of usage:

##### Money accessor

```ruby
class Order < Sequel::Model
  money_accessor :amount, :currency
end

order = Order.create(amount: 200, currency: "EUR")
order.amount # => #<Money fractional:20000.0 currency:EUR>
order.currency # => "EUR"

order.amount = Money.new(150, "RUB")
order.amount # => #<Money fractional:150.0 currency:RUB>
```

##### Money setter

```ruby
class Order < Sequel::Model
  money_setter :amount, :currency
end

order = Order.create(amount: 200, currency: "EUR")
order.amount = Money.new(150, "RUB")
order.currency # => "RUB"
```

##### Money getter

```ruby
class Order < Sequel::Model
  money_getter :amount, :currency
end

order = Order.create(amount: 200, currency: "EUR")
order.amount # => #<Money fractional:20000.0 currency:EUR>
order.currency # => "EUR"
```

## StoreAccessors

Enable: `Sequel::Model.plugin :store_accessors`

Plugin for using jsonb field keys as model properties.

Example:

```ruby
class User < Sequel::Model
  store :data, :first_name
end

user = User.create(first_name: "John")
user.first_name # => "John"
user.data # => {"first_name": "John"}
```

## Synchronize

**Important:** requires a `synchronize` extension described below.

Same as `DB#synchronize_with`

Enable:

```ruby
DB.extension :synchronize
Sequel::Model.plugin :synchronize
```

Example:

```ruby
user = User.first
user.synchronize([:ruby, :forever]) { p "Hey, I'm in transaction!"; sleep 5 }
```

## Upsert

Enable: `Sequel::Model.plugin :upsert`

Plugin for create an "UPSERT" requests to database.

Example:

```ruby
User.upsert(name: "John", email: "jd@test.com", target: :email)
User.upsert_dataset.insert(name: "John", email: "jd@test.com")
```

## WithLock

Enable: `Sequel::Model.plugin :with_lock`

Plugin for locking row for update.

Example:

```ruby
user = User.first
user.with_lock do
  user.update(name: "James")
end
```

## TimestampMigratorUndoExtension
Allows to undo a specific migration

Example:

```ruby
m = Sequel::TimestampMigrator.new(DB, "db/migrations")
m.undo(1549624163) # 1549624163 is a migration version
```

Also you can use `sequel:undo` rake task for it.
Example:

```sh
rake sequel:undo VERSION=1549624163
```

## License
Released under MIT License.

## Authors
Created by Aleksey Bespalov.

<a href="https://github.com/umbrellio/">
  <img style="float: left;" src="https://umbrellio.github.io/Umbrellio/supported_by_umbrellio.svg" alt="Supported by Umbrellio" width="439" height="72">
</a>
