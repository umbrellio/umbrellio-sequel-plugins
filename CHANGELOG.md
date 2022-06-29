# Changelog
All notable changes to this project will be documented in this file.

## [0.8.0] 2022-06-29
### Added

- `rails dbconsole` command support for Sequel (also aliased as `rails db`) for easy access to the DB console. See the README for installation instructions.

## [0.7.0] 2022-06-24
### Added
- `DB.extension(:set_local)` - allows to set transaction locals;
- Support of transaction options via `transaction_options` in migrations;

## [0.6.0] 2022-06-15
### Added
- `mode` param for `Sequel::Model.plugin(:with_lock)`, defaults to `FOR NO KEY UPDATE`;

## [0.5.0] 2020-06-06
### Added
- `Sequel::Model.plugin(:attr_encrypted)` - encrypts to model attributes;

## [0.4.0] 2019-11-18
### Added
- `Sequel.extension(:deferrable_foreign_keys)` - makes foreign keys constraints deferrable by default;

## [0.3.2] 2018-07-03
### Added
- Support sequel expressions in `with_rates`;

## [0.3.0] 2018-04-24
### Added
- `currency_column` param for `CurrencyRates.with_rates`;

## [0.2.0] 2018-03-28
### Added
- `Sequel.extension(:methods_in_migrations)` - support for method definitions in `Sequel.migration` instructions;
