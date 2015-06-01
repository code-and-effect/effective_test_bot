require 'rails_helper'

feature 'Home Page' do
  it 'loads successfully' do
    visit root_url
    expect(page.status_code).to eq 200
  end
end
