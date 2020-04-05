# frozen_string_literal: true

module Cibbot
  module Telegram
    module Emoji
      EMOJI = {
        sos: "\u{1F198}",
        wave: "\u{1F44B}",
        info: "\u{2139}",
        pushpin: "\u{1F4CD}",
        calendar: "\u{1F4C5}",
        check: "\u{2705}",
        uncheck: "\u{274C}",
        cry: "\u{1F622}",
        lovehorns: "\u{1F91F}",
        callme: "\u{1F919}",
        like: "\u{1F44D}",
      }.freeze

      def emoji(name)
        EMOJI[name.to_sym]
      end
    end
  end
end
