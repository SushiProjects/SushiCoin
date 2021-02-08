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

module ::Axentro::Core::NodeComponents
  MINER_BOUNDARY      = 600_000 # 10 mins
  BLOCK_BOUNDARY      = 120_000 # 2 mins
  MOVING_AVERAGE_SIZE =      20

  class NonceMeta
    property difficulty : Int32
    property last_found_time : Int64
    property deviance : Int64?

    def initialize(@difficulty, @last_found_time, @deviance = nil); end
  end

  struct NonceSpacingResult
    property difficulty : Int32
    property reason : String

    def initialize(@difficulty, @reason); end
  end

  class NonceSpacing
    @nonce_meta_map : Hash(String, Array(NonceMeta)) = {} of String => Array(NonceMeta)

    def initialize
    end

    def get_meta_map(mid : String)
      @nonce_meta_map[mid]?
    end

    def leading_miner(miners : Array(Miner)) : Miner?
      grouped = miners.group_by(&.difficulty)
      return unless grouped.keys.size > 0
      grouped[grouped.keys.sort.last].first
    end

    def compute(miner : Miner, in_check : Bool = false) : NonceSpacingResult?
      # The miner should be tracked in nonce_meta to apply throttling
      if nonce_meta = @nonce_meta_map[miner.mid]?
        # did miner find any nonces yet?
        found_nonces = nonce_meta.reject(&.deviance.nil?)
        # info "did miner find nonces yet?"
        if found_nonces.size > 0
          # yes miner found nonces

          # should we use averages or last nonce strategy?
          if found_nonces.size > MOVING_AVERAGE_SIZE
            # use averages from moving average size
            moving_average = nonce_meta.last(MOVING_AVERAGE_SIZE).reject(&.deviance.nil?)
            average_deviance = (moving_average.map(&.deviance.not_nil!).sum.to_i / moving_average.size).to_i
            average_difficulty = (moving_average.map(&.difficulty).sum.to_i / moving_average.size).to_i
            if average_deviance < MINER_BOUNDARY
              return if in_check
              increase_difficulty_by_average(miner, average_difficulty, average_deviance)
            else
              decrease_difficulty_by_average(miner, average_difficulty, average_deviance)
            end
          else
            # if last nonce was found less than 10 mins increase difficulty
            last_nonce_found = found_nonces.last.last_found_time
            deviation = __timestamp - last_nonce_found
            if deviation < MINER_BOUNDARY
              return if in_check
              verbose "found nonce within 10 mins so increase difficulty"
              increase_difficulty_by_last(miner, deviation)
            else
              # else decrease difficulty
              verbose "found nonce later than 10 mins so decrease difficulty"
              decrease_difficulty_by_last(miner)
            end
          end
        else
          # no miner did not find any nonces yet
          verbose "no nonces found yet so decrease difficulty"
          decrease_difficulty_by_last(miner)
        end
      end
    end

    def decrease_difficulty_by_last(miner)
      last_difficulty = miner.difficulty
      miner.difficulty = Math.max(1, last_difficulty - 1)
      if last_difficulty != miner.difficulty
        verbose "(#{miner.mid}) (last nonce) decrease difficulty to #{miner.difficulty}"
        return NonceSpacingResult.new(miner.difficulty, "dynamically decreasing difficulty from #{last_difficulty} to #{miner.difficulty}")
      end
    end

    def decrease_difficulty_by_average(miner, average_difficulty, average_deviance)
      last_difficulty = miner.difficulty
      miner.difficulty = Math.max(1, average_difficulty - 1)
      if last_difficulty != miner.difficulty
        verbose "(#{miner.mid}) (average) decrease difficulty to #{miner.difficulty} for average deviance: #{average_deviance}"
        return NonceSpacingResult.new(miner.difficulty, "dynamically decreasing difficulty from #{last_difficulty} to #{miner.difficulty}")
      end
    end

    def increase_difficulty_by_last(miner, last_deviance)
      last_difficulty = miner.difficulty
      miner.difficulty = Math.max(1, last_difficulty + 4)
      if last_difficulty != miner.difficulty
        action = (last_difficulty > miner.difficulty) ? "decreasing" : "increasing"
        verbose "(#{miner.mid}) (last nonce) #{action} difficulty to #{miner.difficulty} for last deviance: #{last_deviance}"
        return NonceSpacingResult.new(miner.difficulty, "dynamically #{action} difficulty from #{last_difficulty} to #{miner.difficulty}")
      end
    end

    def increase_difficulty_by_average(miner, average_difficulty, average_deviance)
      last_difficulty = miner.difficulty
      miner.difficulty = Math.max(1, average_difficulty + 4)
      if last_difficulty != miner.difficulty
        action = (last_difficulty > miner.difficulty) ? "decreasing" : "increasing"
        verbose "(#{miner.mid}) (average) #{action} difficulty to #{miner.difficulty} for average deviance: #{average_deviance}"
        return NonceSpacingResult.new(miner.difficulty, "dynamically #{action} difficulty from #{last_difficulty} to #{miner.difficulty}")
      end
    end

    def track_miner_difficulty(mid : String, difficulty : Int32)
      last_change = __timestamp
      if nonce_meta = @nonce_meta_map[mid]?
        # already being tracked so add latest data
        last_nonce_data = nonce_meta.last.last_found_time
        deviance = last_change - last_nonce_data
        @nonce_meta_map[mid] << NonceMeta.new(difficulty, last_change, deviance)
      else
        # not tracked yet - so add to tracking
        @nonce_meta_map[mid] ||= [] of NonceMeta
        @nonce_meta_map[mid] << NonceMeta.new(difficulty, last_change)
      end
    end

    include Logger
  end
end