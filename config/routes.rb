Rails.application.routes.draw do
  root 'users#index'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users

  resources :users, only: [:index, :show]

  resources :games, only: [:create, :show] do
    put 'help', on: :member # помощь зала
    put 'answer', on: :member # ответ на текущий вопрос
    put 'take_money', on: :member #  игрок берет деньги
  end

  resource :questions, only: [:new, :create]
end
