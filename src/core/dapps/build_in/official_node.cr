# Copyright © 2017-2020 The Axentro Core developers
#
# See the LICENSE file at the top-level directory of this distribution
# for licensing information.
#
# Unless otherwise agreed in a custom licensing agreement with the Axentro Core developers,
# no part of this software, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in the
# LICENSE file.
#
# Removal or modification of this copyright notice is prohibited.

module ::Axentro::Core::DApps::BuildIn
  class OfficialNode < DApp
    def setup
    end

    def transaction_actions : Array(String)
      ["create_offical_node_slow", "create_offical_node_fast"]
    end

    def transaction_related?(action : String) : Bool
      transaction_actions.includes?(action)
    end

    def valid_transactions?(transactions : Array(Transaction)) : ValidatedTransactions
      # force all to be invalid for now until we have a mechanism to administer official_nodes
      ValidatedTransactions.empty
    end

    def record(chain : Blockchain::Chain)
    end

    def clear
    end

    def define_rpc?(call, json, context, params) : HTTP::Server::Context?
      # case call
      # when "nodes"
      #   return nodes(json, context, params)
      # when "node"
      #   return node(json, context, params)
      # when "node_id"
      #   return node_id(json, context, params)
      # when "node_address"
      #   return node_address(json, context, params)
      # when "official_nodes"
      #   return official_nodes(json, context, params)
      # end

      nil
    end

    def all_impl : Array(String)
      database.get_official_nodes.values.flatten.uniq
    end

    def all_slow_impl : Array(String)
      database.get_official_nodes["slownodes"].uniq
    end

    def all_fast_impl : Array(String)
      database.get_official_nodes["fastnodes"].uniq
    end

    def i_am_a_fastnode?(address : String) : Bool
      all_fast_impl.includes?(address)
    end

    def a_fastnode_is_online?(online_nodes : Array(String)) : Bool
      all_fast_impl.each do |fn|
        return true if online_nodes.includes?(fn)
      end
      false
    end

     # At the moment we don't want to publicise the official_node dapp
     def self.apply_exclusions(dapps : Array(Axentro::Core::DApps::DApp)) : Array(Axentro::Core::DApps::DApp)
        dapps.reject{|dapp| dapp.class.to_s == "Axentro::Core::DApps::BuildIn::OfficialNode" }
      end

    def on_message(action : String, from_address : String, content : String, from = nil)
      false
    end
  end
end
