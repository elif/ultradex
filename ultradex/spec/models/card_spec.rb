require 'rails_helper'

RSpec.describe Card, type: :model do
  let(:redis) { Rails.application.config.redis_client }
  let(:valid_attributes) do
    {
      card_uuid: "1-025-N-S", # set_release_number-pokedex_number-variant-frame
      pokemon_species_name: "Pikachu",
      card_name: "Pikachu Base Set",
      national_pokedex_number: "025",
      original_set_id: "base1",
      set_name: "Base Set",
      series_name: "Original Series",
      release_date: "1999-01-09",
      card_number_in_set: "58/102",
      rarity: "Common",
      card_type: "Pokémon",
      pokemon_types: "Lightning",
      hp: 40,
      illustrator_name: "Mitsuhiro Arita",
      image_url_small: "http://example.com/pikachu_sm.png",
      image_url_large: "http://example.com/pikachu_lg.png",
      approximate_price_usd: 1.23,
      last_price_update_timestamp: Time.now.to_i,
      notes: "1st Edition",
      # UUID components are part of the card_uuid and also stored in hash
      set_release_number: "1",
      variant_code: "N",
      frame_code: "S"
    }
  end

  let(:attributes_for_uuid_generation) do
    valid_attributes.except(:card_uuid).merge(
      set_release_number: "2",
      pokedex_number: "006", # For Charizard
      variant_code: "H",
      frame_code: "F",
      national_pokedex_number: "006", # Ensure this matches pokedex_number for UUID
      card_name: "Charizard Holo",
      pokemon_species_name: "Charizard"
    )
  end


  before(:each) do
    redis.flushdb # Clean database before each test
    # Ensure scripts are loaded if not already (e.g. if Redis was flushed after app boot)
    # This might be redundant if the RedisScripts.execute handles NOSCRIPT,
    # but can be useful for ensuring a clean state for script testing.
    RedisScripts.load_all_scripts
  end

  describe ".find" do
    context "when the card exists" do
      it "returns a Card instance with correct attributes", core_redis_op: true do
        Card.create(valid_attributes) # Create card first
        card = Card.find(valid_attributes[:card_uuid])

        expect(card).to be_a(Card)
        expect(card.card_uuid).to eq(valid_attributes[:card_uuid])
        expect(card.card_name).to eq(valid_attributes[:card_name])
        expect(card.national_pokedex_number).to eq(valid_attributes[:national_pokedex_number])
        expect(card.hp).to eq(40) # Check integer conversion
        expect(card.approximate_price_usd).to eq(1.23) # Check float conversion
        expect(card.release_date).to eq(Date.parse("1999-01-09")) # Check date conversion
      end
    end

    context "when the card does not exist" do
      it "returns nil" do
        expect(Card.find("non-existent-uuid")).to be_nil
      end
    end

    context "when Redis returns invalid JSON" do
      it "logs an error and returns nil" do
        allow(RedisScripts).to receive(:execute).with(:get_card, keys: ["bad-json-uuid"]).and_return("this is not json")
        expect(Rails.logger).to receive(:error).with(/JSON::ParserError in Card.find for UUID bad-json-uuid/)
        expect(Card.find("bad-json-uuid")).to be_nil
      end
    end
  end

  describe ".create" do
    context "with valid attributes and explicit card_uuid" do
      it "creates a card in Redis and returns a Card instance", core_redis_op: true do
        card = Card.create(valid_attributes)
        expect(card).to be_a(Card)
        expect(card.errors).to be_empty
        expect(card.card_uuid).to eq(valid_attributes[:card_uuid])

        # Verify data in Redis (using HGETALL through Lua for consistency or direct HGETALL)
        raw_card_data_json = redis.evalsha(RedisScripts.sha_for(:get_card), keys: [valid_attributes[:card_uuid]])
        expect(raw_card_data_json).not_to be_nil
        raw_card_data = JSON.parse(raw_card_data_json)

        expect(raw_card_data["card_name"]).to eq(valid_attributes[:card_name])
        expect(raw_card_data["national_pokedex_number"]).to eq(valid_attributes[:national_pokedex_number])
        expect(raw_card_data["variant_code"]).to eq("N") # From UUID
        expect(raw_card_data["frame_code"]).to eq("S")   # From UUID
        expect(raw_card_data["set_release_number"]).to eq("1") # From UUID
      end
    end

    context "with valid attributes for UUID generation" do
      it "generates card_uuid, creates card, and returns instance" do
        card = Card.create(attributes_for_uuid_generation)
        expected_uuid = "2-006-H-F" # set_release_number-pokedex_number-variant-frame

        expect(card).to be_a(Card)
        expect(card.errors).to be_empty
        expect(card.card_uuid).to eq(expected_uuid)
        expect(card.card_name).to eq(attributes_for_uuid_generation[:card_name])

        raw_card_data_json = redis.evalsha(RedisScripts.sha_for(:get_card), keys: [expected_uuid])
        expect(raw_card_data_json).not_to be_nil
        raw_card_data = JSON.parse(raw_card_data_json)
        expect(raw_card_data["card_name"]).to eq(attributes_for_uuid_generation[:card_name])
        expect(raw_card_data["national_pokedex_number"]).to eq("006")
      end
    end

    context "when card_uuid and its components are missing" do
      it "raises an ArgumentError" do
        invalid_attrs = valid_attributes.except(:card_uuid, :set_release_number, :pokedex_number, :variant_code, :frame_code)
        expect { Card.create(invalid_attrs) }.to raise_error(ArgumentError, /card_uuid or its components .* must be provided/)
      end
    end

    context "when Redis script returns an error" do
      it "returns a card instance with errors" do
        allow(RedisScripts).to receive(:execute).with(:add_card, anything).and_return("Redis script execution failed")
        card = Card.create(valid_attributes)
        expect(card).to be_a(Card)
        expect(card.errors[:base]).to include("Failed to save card to Redis: Redis script execution failed")
      end
    end
  end

  describe "finders" do
    let!(:card1) { Card.create(valid_attributes.merge(card_uuid: "1-025-N-S", national_pokedex_number: "025", original_set_id: "base1", illustrator_name: "Mitsuhiro Arita")) }
    let!(:card2) { Card.create(valid_attributes.merge(card_uuid: "1-025-H-S", national_pokedex_number: "025", original_set_id: "base1", illustrator_name: "Ken Sugimori", card_name: "Pikachu Holo")) }
    let!(:card3) { Card.create(valid_attributes.merge(card_uuid: "2-006-N-S", national_pokedex_number: "006", original_set_id: "base2", illustrator_name: "Mitsuhiro Arita", card_name: "Charizard")) }

    describe ".find_by_pokemon" do
      it "returns cards matching the Pokédex number", core_redis_op: true do
        cards = Card.find_by_pokemon("025")
        expect(cards.map(&:card_uuid)).to match_array(["1-025-N-S", "1-025-H-S"])
      end

      it "returns an empty array if no cards match" do
        expect(Card.find_by_pokemon("999")).to be_empty
      end
    end

    describe ".find_by_set" do
      it "returns cards matching the original set ID" do
        cards = Card.find_by_set("base1")
        expect(cards.map(&:card_uuid)).to match_array(["1-025-N-S", "1-025-H-S"])
      end
    end

    describe ".find_by_illustrator" do
      it "returns cards matching the illustrator name (case-insensitive, normalized)" do
        # add_card.lua normalizes "Mitsuhiro Arita" to "mitsuhiro_arita"
        cards = Card.find_by_illustrator("Mitsuhiro Arita")
        expect(cards.map(&:card_uuid)).to include("1-025-N-S", "2-006-N-S")

        cards_sugimori = Card.find_by_illustrator("Ken Sugimori")
        expect(cards_sugimori.map(&:card_uuid)).to include("1-025-H-S")
      end
       it "handles names with spaces and special characters correctly" do
        Card.create(valid_attributes.merge(card_uuid: "3-007-N-S", illustrator_name: "Kouki Saitou", national_pokedex_number: "007"))
        cards = Card.find_by_illustrator("Kouki Saitou") # Model normalizes to kouki_saitou
        expect(cards.map(&:card_uuid)).to include("3-007-N-S")
      end
    end
  end

  describe "#update_price" do
    let!(:card) { Card.create(valid_attributes) }

    it "updates the card's price in Redis and on the instance", core_redis_op: true do
      timestamp = Time.now.to_i + 3600
      expect(card.update_price(5.99, timestamp)).to be true
      expect(card.approximate_price_usd).to eq(5.99)
      expect(card.last_price_update_timestamp).to eq(timestamp)

      # Verify in Redis
      updated_card_data_json = redis.evalsha(RedisScripts.sha_for(:get_card), keys: [card.card_uuid])
      updated_card_data = JSON.parse(updated_card_data_json)
      expect(updated_card_data["approximate_price_usd"].to_f).to eq(5.99)
      expect(updated_card_data["last_price_update_timestamp"].to_i).to eq(timestamp)
    end

    it "returns false if card_uuid is blank" do
      new_card = Card.new(valid_attributes.except(:card_uuid))
      expect(new_card.update_price(1.00)).to be false
    end

    it "returns false and adds error if Redis script fails" do
      allow(RedisScripts).to receive(:execute).with(:update_card_price, anything).and_return("Error")
      expect(card.update_price(10.00)).to be false
      expect(card.errors[:base]).to include("Failed to update price in Redis: Error")
    end
  end

  describe "#save" do
    context "when updating an existing card" do
      let!(:card) { Card.create(valid_attributes) }

      it "updates attributes in Redis and returns true", core_redis_op: true do
        card.card_name = "Pikachu (Updated)"
        card.hp = 50
        expect(card.save).to be true
        expect(card.errors).to be_empty

        # Verify in Redis
        updated_card = Card.find(card.card_uuid)
        expect(updated_card.card_name).to eq("Pikachu (Updated)")
        expect(updated_card.hp).to eq(50)
      end

      it "re-indexes if relevant attributes change (e.g. illustrator_name)" do
        original_illustrator_normalized = "mitsuhiro_arita"
        new_illustrator_normalized = "john_doe"

        # Check initial index
        initial_illustrator_cards = redis.smembers("idx:illustrator_cards:#{original_illustrator_normalized}")
        expect(initial_illustrator_cards).to include(card.card_uuid)

        card.illustrator_name = "John Doe" # This will be normalized to "john_doe"
        expect(card.save).to be true

        # Check old index (should be removed by SADD if card_uuid was only one, or just not added again)
        # The add_card script uses SADD, which adds if not present. It doesn't remove from old indexes.
        # This is a limitation of simple upsert for index changes.
        # For this test, we'll verify the new index. A more robust system would handle index moves.

        updated_illustrator_cards = redis.smembers("idx:illustrator_cards:#{new_illustrator_normalized}")
        expect(updated_illustrator_cards).to include(card.card_uuid)

        # To properly test removal from old index, the add_card script would need to be more complex
        # or a separate process would handle such changes.
        # For now, we confirm it's added to the new one.
      end
    end

    context "when card_uuid is blank" do
      it "adds an error and returns false" do
        new_card = Card.new(valid_attributes.except(:card_uuid))
        expect(new_card.save).to be false
        expect(new_card.errors[:base]).to include("Cannot save a new record without calling Card.create or providing UUID components.")
      end
    end

    context "when validations fail" do
      let!(:card) { Card.create(valid_attributes) }
      it "does not save and returns false" do
        card.card_name = "" # Assuming card_name has a presence validation
        expect(card.save).to be false
        expect(card.errors[:card_name]).to include("can't be blank") # or appropriate message
      end
    end
  end

  describe "#persisted?" do
    it "returns true if card_uuid is present" do
      card = Card.new(card_uuid: "some-uuid")
      expect(card.persisted?).to be true
    end

    it "returns false if card_uuid is blank" do
      card = Card.new
      expect(card.persisted?).to be false
    end
  end

  describe "UUID helpers" do
    describe ".generate_uuid" do
      it "generates a correctly formatted UUID" do
        uuid = Card.generate_uuid(set_release_number: "123", pokedex_number: "025", variant_code: "R", frame_code: "F")
        expect(uuid).to eq("123-025-R-F")
      end
       it "upcases variant and frame codes" do
        uuid = Card.generate_uuid(set_release_number: "123", pokedex_number: "001", variant_code: "n", frame_code: "s")
        expect(uuid).to eq("123-001-N-S")
      end
    end

    describe "#parse_uuid" do
      it "parses a valid UUID into components" do
        card = Card.new(card_uuid: "123-025-R-F")
        components = card.parse_uuid
        expect(components).to eq({
          set_release_number: "123",
          pokedex_number: "025",
          variant_code: "R",
          frame_code: "F"
        })
      end

      it "returns nil for an invalid UUID" do
        card = Card.new(card_uuid: "invalid-uuid")
        expect(card.parse_uuid).to be_nil
      end

      it "returns nil if card_uuid is blank" do
        card = Card.new(card_uuid: "")
        expect(card.parse_uuid).to be_nil
      end
    end
  end
end
