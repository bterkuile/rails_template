$use_ember = yes? "Use ember?"
def ember?; $use_ember end

gsub_file "Gemfile", "gem 'turbolinks'", "#gem 'turbolinks'"
gsub_file "Gemfile", "gem 'sqlite3'", "#gem 'sqlite3'"
gsub_file "Gemfile", "gem 'sass-rails'", "#gem 'sass-rails'"
gsub_file "Gemfile", "gem 'coffee-rails'", "#gem 'coffee-rails'"
gsub_file "Gemfile", "gem 'jbuilder'", "#gem 'jbuilder'"
gsub_file "Gemfile", "gem 'spring'", "#gem 'spring'"

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
  inside "app/assets/javascripts" do
    run "mkdir app"
    %w[views models templates modifications].each do |ember_dir|
      run "mkdir app/#{ember_dir}"
    end

    file "app/store.js.coffee", <<-CODE
      App.ApplicationSerializer = DS.ActiveModelSerializer

      App.CustomAdapter = DS.RESTAdapter.extend
        # user underscored paths
        pathForType: (type)->
          decamelized = Ember.String.decamelize(type)
          Ember.String.pluralize(decamelized)

      App.Store = DS.Store.extend
        adapter: App.CustomAdapter
    CODE

    file "app/modifications/model_modifications.js.coffee", <<-CODE
      DS.Model.reopen
        created_at: DS.attr('date')
        updated_at: DS.attr('date')
        eraseRecord: ->
          @clearRelationships()
          @transitionTo('deleted.saved')
    CODE

    file "app/application.js.coffee", <<-CODE
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
  end
end

inside "app/views/templates" do
  remove_file "application.html.erb"

  file "application.html.slim", <<-CODE
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

  file "app.html.slim", <<-CODE
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
