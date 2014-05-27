$use_ember = yes? "Use ember?"
$use_js_routes = yes? 'Use js-routes?'
def ember?; $use_ember end
def js_routes?; $use_js_routes end

def trail_file(file_name, string, options={})
  first_line = string.split(/\n/).first
  indent = first_line.match(/^\s*/)[0].length
  file file_name, string.gsub(/^\s{#{indent}}/, ''), options
end

gsub_file "Gemfile", "gem 'turbolinks'", "#gem 'turbolinks'"
gsub_file "Gemfile", "gem 'sqlite3'", "#gem 'sqlite3'"
gsub_file "Gemfile", "gem 'sass-rails'", "#gem 'sass-rails'"
gsub_file "Gemfile", "gem 'coffee-rails'", "#gem 'coffee-rails'"
gsub_file "Gemfile", "gem 'jbuilder'", "#gem 'jbuilder'"
gsub_file "Gemfile", "gem 'spring'", "#gem 'spring'"
insert_into_file "config/application.rb", "
require 'rails'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'rails/test_unit/railtie'
require 'sprockets/railtie'
", after: "require 'rails/all'"
gsub_file "config/application.rb", "require 'rails/all'", "#require 'rails/all'"

if ember?
  gem 'ember-source'
  gem 'ember-rails'
end
gem 'slim-rails'
gem 'couch_potato' , github: 'bterkuile/couch_potato'
gem 'simply_stored', github: 'bterkuile/simply_stored'
gem 'orm_adapter', github: 'bterkuile/orm_adapter'
gem 'devise'
gem 'devise_simply_stored', github: 'bterkuile/devise_simply_stored'

gem_group :assets do
  gem 'sass-rails', '~> 4.0.3'
  gem 'uglifier', '>= 1.3.0'
  gem 'coffee-rails', '~> 4.0.0'
  gem 'emblem-rails'
  gem 'foundation-rails'
  gem "font-awesome-rails"
  if js_routes?
    gem 'js-routes'
  end
end

gem_group :development do
  gem 'rspec-rails'
  gem 'quiet_assets'
  gem 'letter_opener'
  gem 'thin'
  gem 'pry-rails'
end

gem_group :test do
  gem 'rspec-rails'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'turnip'
  gem 'launchy'
  gem 'fuubar'
  gem 'simplecov', require: false
  gem 'factory_girl_rails'
  gem 'pry'
end

if ember?
  application "config.handlebars.templates_root = %w[app/templates]"
  inside "app/assets" do
    inside 'javascripts' do
      run "mkdir app"
      %w[views models templates modifications components].each do |ember_dir|
        run "mkdir app/#{ember_dir}"
      end

      trail_file "app/store.js.coffee", <<-CODE
        App.ApplicationSerializer = DS.ActiveModelSerializer
        App.CustomAdapter = DS.RESTAdapter.extend
          # use underscored paths, ember default is lower camelcase resource paths (Ember Data 1.0.0 beta8)
          pathForType: (type)->
            decamelized = Ember.String.decamelize(type)
            Ember.String.pluralize(decamelized)
        App.Store = DS.Store.extend
          adapter: App.CustomAdapter
      CODE

      trail_file "app/modifications/model_modifications.js.coffee", <<-CODE
        DS.Model.reopen
          created_at: DS.attr('date')
          updated_at: DS.attr('date')
          eraseRecord: ->
            @clearRelationships()
            @transitionTo('deleted.saved')
      CODE

      trail_file "app/application.js.coffee", <<-CODE
        #= require jquery
        #= require jquery_ujs
        #= require_self
        #= require handlebars
        #= require ember
        #= require ember-data
        #= require_directory ./modifications
        #= require_tree .
        @EmberENV = {FEATURES: {'query-params-new': true}}
      CODE
      insert_into_file "app/application.js.coffee", "#= require js-routes\n", after: "require_self\n" if js_routes?
    end

    inside "stylesheets" do
      remove_file "application.css"
      trail_file "application.css.sass", <<-CODE
        //= require_directory .
      CODE
      run "mkdir app"
      trail_file "app/application.css.sass", <<-CODE
        //= require_tree .
      CODE
    end
  end
end

inside "app/views/layouts" do
  remove_file "application.html.erb"

  trail_file "application.html.slim", <<-CODE
    doctype html
    html lang="en"
      head
        meta charset="utf-8"
        meta http-equiv="X-UA-Compatible" content="IE=Edge,chrome=1"
        meta name="viewport" content="width=device-width, initial-scale=1.0"
        title= content_for?(:title) ? yield(:title) : application_title
        = stylesheet_link_tag "application", media: "all"
        = javascript_include_tag 'application'
        = csrf_meta_tags
      body
  CODE

  if ember?
    trail_file "app.html.slim", <<-CODE
      doctype html
      html lang="en"
        head
          meta charset="utf-8"
          meta http-equiv="X-UA-Compatible" content="IE=Edge,chrome=1"
          meta name="viewport" content="width=device-width, initial-scale=1.0"
          title= content_for?(:title) ? yield(:title) : application_title
          = stylesheet_link_tag "app/application", media: "all"
          = javascript_include_tag 'app/application'
        body
          #application-container
    CODE
  end
end
insert_into_file "app/helpers/application_helper.rb", %|  def application_title\n    "#{@app_name.to_s.camelize}"\n  end\n|, after: "module ApplicationHelper\n"

# bundle install is a user action, do not doe automagically
def run_bundle ; end
