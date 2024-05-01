# Code0::License

`Code0::License` can create and validate software licenses.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add code0-license

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install code0-license

## Usage

To start using the gem, you need to have a public and private RSA key.
If you don't have a key pair, you can generate one by running `bin/create_key`

To generate a license, use the private key as encryption key:

```ruby
require "code0/license"

# read private key from file
private_key_file = File.read('license_key.key')
private_key = OpenSSL::PKey::RSA.new(private_key_file)

# set private key as encryption key
Code0::License.encryption_key = private_key

# create a license
license = Code0::License.new(
  {
    'licensee' => { 'company' => 'Code0' }, # content of licensee can be as you want, it just can't be empty
    'start_date' => '2024-05-01', # when is the first date where this license is valid?
    'end_date' => '2025-05-01', # until when is the license valid?
    'restrictions' => {}, # content can be as you wish, can be used to semantically store some restrictions that are evaluated by your application
    'options' => {}, # content can be as you wish, can be used to semantically provide some options of this license
  }
)

# export the license
File.write('license.txt', Code0::License.export(license, 'CODE0'))
```

To verify the license in your application, use the public key

```ruby
require "code0/license"

# read public key from file
public_key_file = File.read('license_key.pub')
public_key = OpenSSL::PKey::RSA.new(public_key_file)

# set public key as encryption key
Code0::License.encryption_key = public_key

# load the license
license = Code0::License.load(File.read('license.txt'))

# exit if license is valid or outside of the valid time
exit unless license.valid?
exit unless license.in_active_time?

# for example, exit if users exceed licensed amount
exit if User.count > license.restrictions['user_count']
```
