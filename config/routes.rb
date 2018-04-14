Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root 'welcome#index'

# mount Crono::Web, at: '/crono'
  namespace :api do
    namespace :services do
      controller :services do
        # get :get_fields
        # get :get_objects
        # get :get_object_records
        # get :get_organization_details
        # get :get_error_log
        get :get_supported_integration
        get :get_mapping
        get :get_supported_integration2
        get :get_mapping2
        get :get_mapping3
        get :start_sync
        post :get_logs
        get :send_email
        get :get_every_day_sync_details
        # get :connectorjob
        # post :set_scheduling_details
        # post :set_send_email_status
        post :store_json_data
        post :save_mapping
        post :validate_credentials
        post :delete_mapping
        post :set_token
      end
    end
  end
  # match 'api/services/save_mapping/*', to: 'welcome#render_routing_error', via: [:get, :post, :put, :delete]
  # match 'api/services/../*', to: 'welcome#render_routing_error', via: [:get, :post, :put, :delete]
  match '/', to: 'welcome#render_routing_error', via: [:get, :post, :put, :delete]
  match '/api', to: 'welcome#render_routing_error', via: [:get, :post, :put, :delete]
  match '/api/services', to: 'welcome#render_routing_error', via: [:get, :post, :put, :delete]
    # match 'api/v1/save_mapping*', to "controller: 'welcome/render_routing_error'", via: [:get, :post, :put, :delete]
  # map.connect '*', :controller => 'api/services', :action => 'routing'

  # match ':not_found' => 'api/services#routing',
  # :constraints => { :not_found => "save_mapping/.*/" }, via: :get
  # match '/.*/', :to => 'errors#api/services/routing'
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
