# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module Google
  module Cloud
    module Storage
      class File
        ##
        # # File Access Control List
        #
        # Represents a File's Access Control List.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.acl.readers.each { |reader| puts reader }
        #
        class Acl
          # @private
          RULES = { "authenticatedRead" => "authenticatedRead",
                    "auth" => "authenticatedRead",
                    "auth_read" => "authenticatedRead",
                    "authenticated" => "authenticatedRead",
                    "authenticated_read" => "authenticatedRead",
                    "bucketOwnerFullControl" => "bucketOwnerFullControl",
                    "owner_full" => "bucketOwnerFullControl",
                    "bucketOwnerRead" => "bucketOwnerRead",
                    "owner_read" => "bucketOwnerRead",
                    "private" => "private",
                    "projectPrivate" => "projectPrivate",
                    "project_private" => "projectPrivate",
                    "publicRead" => "publicRead",
                    "public" => "publicRead",
                    "public_read" => "publicRead" }

          ##
          # A boolean value or a project ID string to indicate the project to
          # be billed for operations on the bucket and its files. If this
          # attribute is set to `true`, transit costs for operations on the
          # bucket will be billed to the current project for this client. (See
          # {Project#project} for the ID of the current project.) If this
          # attribute is set to a project ID, and that project is authorized for
          # the currently authenticated service account, transit costs will be
          # billed to that project. This attribute is required with requester
          # pays-enabled buckets. The default is `nil`.
          #
          # In general, this attribute should be set when first retrieving the
          # owning bucket by providing the `user_project` option to
          # {Project#bucket}.
          #
          # See also {Bucket#requester_pays=} and {Bucket#requester_pays}.
          #
          attr_accessor :user_project

          ##
          # @private Initialized a new Acl object.
          # Must provide a valid Bucket object.
          def initialize file
            @bucket = file.bucket
            @file = file.name
            @service = file.service
            @user_project = file.user_project
            @owners  = nil
            @readers = nil
          end

          ##
          # Reloads all Access Control List data for the file.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   file.acl.reload!
          #
          def reload!
            gapi = @service.list_file_acls @bucket, @file,
                                           user_project: user_project
            acls = Array(gapi.items)
            @owners  = entities_from_acls acls, "OWNER"
            @readers = entities_from_acls acls, "READER"
          end
          alias_method :refresh!, :reload!

          ##
          # Lists the owners of the file.
          #
          # @return [Array<String>]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   file.acl.owners.each { |owner| puts owner }
          #
          def owners
            reload! if @owners.nil?
            @owners
          end

          ##
          # Lists the readers of the file.
          #
          # @return [Array<String>]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   file.acl.readers.each { |reader| puts reader }
          #
          def readers
            reload! if @readers.nil?
            @readers
          end

          ##
          # Grants owner permission to the file.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @param [Integer] generation When present, selects a specific
          #   revision of this object. Default is the latest version.
          #
          # @example Grant access to a user by prepending `"user-"` to an email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   email = "heidi@example.net"
          #   file.acl.add_owner "user-#{email}"
          #
          # @example Grant access to a group by prepending `"group-"` to email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   email = "authors@example.net"
          #   file.acl.add_owner "group-#{email}"
          #
          def add_owner entity, generation: nil
            gapi = @service.insert_file_acl @bucket, @file, entity, "OWNER",
                                            generation: generation,
                                            user_project: user_project
            entity = gapi.entity
            @owners.push entity unless @owners.nil?
            entity
          end

          ##
          # Grants reader permission to the file.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @param [Integer] generation When present, selects a specific
          #   revision of this object. Default is the latest version.
          #
          # @example Grant access to a user by prepending `"user-"` to an email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   email = "heidi@example.net"
          #   file.acl.add_reader "user-#{email}"
          #
          # @example Grant access to a group by prepending `"group-"` to email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   email = "authors@example.net"
          #   file.acl.add_reader "group-#{email}"
          #
          def add_reader entity, generation: nil
            gapi = @service.insert_file_acl @bucket, @file, entity, "READER",
                                            generation: generation,
                                            user_project: user_project
            entity = gapi.entity
            @readers.push entity unless @readers.nil?
            entity
          end

          ##
          # Permanently deletes the entity from the file's access control list.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @param [Integer] generation When present, selects a specific
          #   revision of this object. Default is the latest version.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   email = "heidi@example.net"
          #   file.acl.delete "user-#{email}"
          #
          def delete entity, generation: nil
            @service.delete_file_acl \
              @bucket, @file, entity,
              generation: generation, user_project: user_project
            @owners.delete entity  unless @owners.nil?
            @readers.delete entity unless @readers.nil?
            true
          end

          # @private
          def self.predefined_rule_for rule_name
            RULES[rule_name.to_s]
          end

          # Predefined ACL helpers

          ##
          # Convenience method to apply the `authenticatedRead` predefined ACL
          # rule to the file.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   file.acl.auth!
          #
          def auth!
            update_predefined_acl! "authenticatedRead"
          end
          alias_method :authenticatedRead!, :auth!
          alias_method :auth_read!, :auth!
          alias_method :authenticated!, :auth!
          alias_method :authenticated_read!, :auth!

          ##
          # Convenience method to apply the `bucketOwnerFullControl` predefined
          # ACL rule to the file.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   file.acl.owner_full!
          #
          def owner_full!
            update_predefined_acl! "bucketOwnerFullControl"
          end
          alias_method :bucketOwnerFullControl!, :owner_full!

          ##
          # Convenience method to apply the `bucketOwnerRead` predefined ACL
          # rule to the file.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   file.acl.owner_read!
          #
          def owner_read!
            update_predefined_acl! "bucketOwnerRead"
          end
          alias_method :bucketOwnerRead!, :owner_read!

          ##
          # Convenience method to apply the `private` predefined ACL
          # rule to the file.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   file.acl.private!
          #
          def private!
            update_predefined_acl! "private"
          end

          ##
          # Convenience method to apply the `projectPrivate` predefined ACL
          # rule to the file.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   file.acl.project_private!
          #
          def project_private!
            update_predefined_acl! "projectPrivate"
          end
          alias_method :projectPrivate!, :project_private!

          ##
          # Convenience method to apply the `publicRead` predefined ACL
          # rule to the file.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   file = bucket.file "path/to/my-file.ext"
          #   file.acl.public!
          #
          def public!
            update_predefined_acl! "publicRead"
          end
          alias_method :publicRead!, :public!
          alias_method :public_read!, :public!

          protected

          def clear!
            @owners  = nil
            @readers = nil
            self
          end

          def update_predefined_acl! acl_role
            patched_file = Google::Apis::StorageV1::Object.new acl: []
            @service.patch_file @bucket, @file, patched_file,
                                predefined_acl: acl_role,
                                user_project: user_project
            clear!
          end

          def entities_from_acls acls, role
            selected = acls.select { |acl| acl.role == role }
            entities = selected.map(&:entity)
            entities
          end
        end
      end
    end
  end
end
