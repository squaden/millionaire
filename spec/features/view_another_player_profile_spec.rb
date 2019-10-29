require 'rails_helper'

RSpec.feature 'View another player profile', type: :feature do

  let(:user) { FactoryGirl.create :user, name: 'fry' }

  let(:first_game) do
      FactoryGirl.create(
        :game,
        user: user,
        current_level: 7,
        created_at: Time.parse('2019-10-29 22:00'),
        finished_at: Time.parse('2019-10-29 22:10'),
        prize: 32000
      )
  end

  let(:second_game) do
    FactoryGirl.create(
      :game,
      user: user,
      current_level: 5,
      created_at: Time.parse('2019-10-29 21:45'),
      finished_at: Time.parse('2019-10-29 22:00'),
      fifty_fifty_used: true,
      prize: 1000
    )
  end
  let!(:games) { [first_game, second_game] }

  scenario 'anonim views another player profile' do
    visit '/'

    click_link 'fry'

    expect(page).to have_current_path "/users/#{user.id}"
    expect(page).to have_content 'fry'
    expect(page).to have_selector 'tr.text-center', count: games.count
    expect(page).not_to have_content 'Сменить имя и пароль'

    expect(page).to have_content '1'
    expect(page).to have_content 'деньги'
    expect(page).to have_content '29 окт., 22:00'
    expect(page).to have_content '7'
    expect(page).to have_content '32 000'

    expect(page).to have_content '2'
    expect(page).to have_content '29 окт., 21:45'
    expect(page).to have_content '5'
    expect(page).to have_content '50/50'
    expect(page).to have_content '1 000'
  end
end
