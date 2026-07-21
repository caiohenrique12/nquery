# frozen_string_literal: true

require "nquery"
require_relative "../rails_helper"

RSpec.describe "Navigation", type: :system do
  it "shows login page" do
    visit "/login"
    expect(page).to have_content("Welcome back")
    expect(page).to have_content("nquery")
  end

  it "signs in and visits home" do
    visit "/login"
    fill_in "email", with: "admin@nquery.dev"
    fill_in "password", with: "password123"
    click_button "Sign in"
    expect(page).to have_content("Home")
  end

  it "navigates to collections index" do
    visit "/login"
    fill_in "email", with: "admin@nquery.dev"
    fill_in "password", with: "password123"
    click_button "Sign in"
    expect(page).to have_content("Home")
    visit "/collections"
    expect(page).to have_content("Our analytics")
  end

  it "navigates to admin groups" do
    visit "/login"
    fill_in "email", with: "admin@nquery.dev"
    fill_in "password", with: "password123"
    click_button "Sign in"
    expect(page).to have_content("Home")
    visit "/admin/groups"
    expect(page).to have_content("Administrators")
    within(".nq-sidebar") do
      expect(page).to have_css("a.nq-nav-link.active", text: "Groups")
    end
    expect(page).to have_css(".nq-breadcrumbs", text: "Home")
    expect(page).to have_css(".nq-breadcrumbs", text: "Groups")
  end

  it "highlights the active sidebar item on dashboards index" do
    visit "/login"
    fill_in "email", with: "admin@nquery.dev"
    fill_in "password", with: "password123"
    click_button "Sign in"
    visit "/dashboards"
    within(".nq-sidebar") do
      expect(page).to have_css("a.nq-nav-link.active", text: "Dashboards")
    end
    expect(page).to have_css(".nq-breadcrumb-item span[aria-current='page']", text: "Dashboards")
  end

  it "highlights the active sidebar item on collections index" do
    visit "/login"
    fill_in "email", with: "admin@nquery.dev"
    fill_in "password", with: "password123"
    click_button "Sign in"
    visit "/collections"
    within(".nq-sidebar") do
      expect(page).to have_css("a.nq-nav-link.active", text: "Collections")
    end
    expect(page).to have_css(".nq-breadcrumb-item span[aria-current='page']", text: "Collections")
  end
end
