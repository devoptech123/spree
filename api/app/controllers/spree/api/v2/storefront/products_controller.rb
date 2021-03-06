module Spree
  module Api
    module V2
      module Storefront
        class ProductsController < ::Spree::Api::V2::BaseController
          include Spree::Api::V2::CollectionOptionsHelpers

          def index
            render_serialized_payload serialize_collection(paginated_collection)
          end

          def show
            render_serialized_payload serialize_resource(resource)
          end

          private

          def serialize_collection(collection)
            dependencies[:collection_serializer].new(
              collection,
              collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            dependencies[:resource_serializer].new(
              resource,
              include: resource_includes
            ).serializable_hash
          end

          def paginated_collection
            dependencies[:collection_paginator].new(sorted_collection, params).call
          end

          def sorted_collection
            dependencies[:collection_sorter].new(collection, params, current_currency).call
          end

          def collection
            dependencies[:collection_finder].new(scope, params, current_currency).call
          end

          def resource
            scope.find_by(slug: params[:id]) || scope.find(params[:id])
          end

          def dependencies
            {
              collection_sorter: Spree::Products::Sort,
              collection_finder: Spree::Products::Find,
              collection_paginator: Spree::Shared::Paginate,
              collection_serializer: Spree::V2::Storefront::ProductSerializer,
              resource_serializer: Spree::V2::Storefront::ProductSerializer
            }
          end

          def collection_options(collection)
            {
              links: collection_links(collection),
              meta: collection_meta(collection),
              include: collection_includes
            }
          end

          def scope
            Spree::Product.includes(scope_includes)
          end

          def default_resource_includes
            %i[
              variants
              variants.images
              default_variant
              default_variant.images
              option_types
              option_types.option_values
              product_properties
            ]
          end

          def scope_includes
            {
              classifications: :taxon,
              product_properties: :property,
              option_types: :option_values,
              variants: %i[default_price option_values]
            }
          end

          alias collection_includes resource_includes
        end
      end
    end
  end
end
