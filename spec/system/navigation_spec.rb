# frozen_string_literal: true

require "nquery"
require_relative "../rails_helper"

RSpec.describe "Navigation", type: :system do
  it "shows login page" do
    visit "/login"
    expect(page).to have_content("Sign in to nquery")
  end

  it "signs in and visits home" do
    visit "/login"
    fill_in "email", with: "admin@nquery.dev"
    fill_in "password", with: "password123"
    click_button "Sign in"
    expect(page).to have_content("Home")
  end

  it "navigates to browse" do
    visit "/login"
    fill_in "email", with: "admin@nquery.dev"
    fill_in "password", with: "password123"
    click_button "Sign in"
    expect(page).to have_content("Home")
    visit "/browse"
    expect(page).to have_content("Collections")
  end

  it "navigates to admin groups" do
    visit "/login"
    fill_in "email", with: "admin@nquery.dev"
    fill_in "password", with: "password123"
    click_button "Sign in"
    expect(page).to have_content("Home")
    visit "/admin/groups"
    expect(page).to have_content("Administrators")
  end
end
