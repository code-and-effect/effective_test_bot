require 'rails_helper'

RSpec.describe 'CRUD Compliance Tests' do
  ['Clinic'].each do |resource|
    feature "#{resource} CRUD Compliance" do
      let(:obj) { resource.constantize.new() }

      scenario 'Has an empty index screen', :js => true do
        visit polymorphic_path(obj)
        page.save_screenshot('something.png')

        expect(page.status_code).to eq 200
        expect(page).to have_content 'There are no'
      end

    end
  end
end


# feature 'CRUD Compliance Test' do
#   [:clinic].each do |resource|
#     feature ''
#   end
# end


# RSpec.describe 'FactoryGirl' do
#   FactoryGirl.factories.map(&:name).each do |factory_name|
#     describe "#{ factory_name } factory" do
#       it 'should be valid' do
#         factory = FactoryGirl.build(factory_name)
#         if factory.respond_to?(:valid?)
#           expect(factory).to be_valid, -> { factory.errors.full_messages.join("\n") }
#         end
#       end

#       FactoryGirl.factories[factory_name].definition.defined_traits.map(&:name).each do |trait_name|
#         context "with trait #{ trait_name }" do
#           it 'should be valid' do
#             factory = FactoryGirl.build(factory_name, trait_name)
#             if factory.respond_to?(:valid?)
#               expect(factory).to be_valid, -> { factory.errors.full_messages.join("\n") }
#             end
#           end
#         end
#       end
#     end
#   end
# end
