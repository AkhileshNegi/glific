defmodule Glific.MessageTagsTest do
  use Glific.DataCase

  alias Glific.{Fixtures, Tags, Tags.MessageTags}

  setup do
    lang = Glific.Seeds.seed_language()
    default_provider = Glific.Seeds.seed_providers()
    Glific.Seeds.seed_organizations(default_provider, lang)
    Glific.Seeds.seed_tag(lang)
    :ok
  end

  test "lets check the edge cases first, no tags, or some crappy tags" do
    message = Fixtures.message_fixture()

    message_tags = MessageTags.create_message_tags(%{message_id: message.id, tags_id: []})
    assert length(message_tags.message_tags) == 0

    message_tags = MessageTags.create_message_tags(%{message_id: message.id, tags_id: [12345, 765843]})
    assert length(message_tags.message_tags) == 0
  end

  test "lets check we can add all the status tags to the message" do
    message = Fixtures.message_fixture()
    tags_map = Tags.status_map()

    message_tags =
      MessageTags.create_message_tags(%{message_id: message.id,
                                        tags_id: Map.values(tags_map)})
    assert length(message_tags.message_tags) == length(Map.values(tags_map))


    # add a random unknown tag_id, and ensure we dont barf
    message_tags =
      MessageTags.create_message_tags(%{message_id: message.id,
                                        tags_id: Map.values(tags_map) ++ ["-1"]})
    assert length(message_tags.message_tags) == length(Map.values(tags_map))
  end
end
