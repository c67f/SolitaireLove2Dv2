io.stdout:setvbuf("no") --print messages immediately

require "card"
require "grabber"
require "pile"

CARD_VALUE = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
SUITS = {"s", "c", "h", "d"}


function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  screenWidth = 640
  screenHeight = 480
  love.window.setMode(screenWidth, screenHeight)
  love.graphics.setBackgroundColor(0.2, 0.7, 0.2, 1)
  
  grabber = GrabberClass:new()
  cardTable = {}
  grabbedCardsTable = {}
  mainPilesTable = {}
  acePilesTable = {}
  mainDeck = PileClass:new(50, 150, false, "deck")
  drawPile = PileClass:new(50, 300, false, "draw")
  
  for i = 1, 4 do
    for j = 1, 13 do
      suit = SUITS[i]
      value = CARD_VALUE[j]
      --print(value)
      table.insert(cardTable, CardClass:new(mainDeck.position.x, mainDeck.position.y, value, suit))
    end
  end
  shuffle(cardTable) --shuffle messing some things up

  for i = 1, 24 do
    --print(_)
    --print("mainDeck card value: "..cardTable[i].value)
    --print("mainDeck card suit: "..cardTable[i].suit)
    mainDeck:push(cardTable[i])
    cardTable[i].faceDown = true
    --print("mainDeck top card suit is: "..mainDeck.cards[1][2])
  end
  
  for i = 1, 7 do
    table.insert(mainPilesTable, PileClass:new(150 + (i-1) * 70, 170, true, "tableau"))
  end
  
  mainCardCount = 52
  for i = 1, 7 do
    for j = 1, i do
      --cardTable[mainCardCount].position.x = mainPilesTable[i].position.x --Uncomment these two lines at the same time as lines 48-53 in card.lua for fun times!
      --cardTable[mainCardCount].position.y = mainPilesTable[i].position.y + (j-1) * 20
      mainPilesTable[i]:push(cardTable[mainCardCount])
      cardTable[mainCardCount].pile = mainPilesTable[i]
      cardTable[mainCardCount].inPile = true
      --if j ~= i then
      cardTable[mainCardCount].faceDown = true --set all but the last card in each pile to be face down
      --end
      --print("card in main piles: "..mainPilesTable[i].top)
      mainCardCount = mainCardCount - 1
      --mainPilesTable[2].position.y = 50
    end
  end
  --table.insert(mainPilesTable, mainDeck)
  
  for i = 1, 4 do
    table.insert(acePilesTable, PileClass:new(160 + (i-1)*70, 70, false, "ace"))
  end
  if acePilesTable[1].cascade == true then
    print("ace pile 1 cascades")
  end
  
  print("total number of cards: " .. #cardTable)

end

function love.update()
  --print("updating grabber")
  grabber:update()

  
  --print("updating cards")
  for _, card in ipairs(cardTable) do --key is _, value is entity (don't care about the key, but ipairs(entity table) returns two things so we need a place to store the first (the key)
    --print(_)
    card:update(grabber) --our update function we made
    if card.inPile == true and grabber.grabbing == false then --don't update while moving a card, so that the face down code in card.lua works properly
      --print("card in a pile")
      card.pileMax = #card.pile.cards
      --print("card pileMax: " .. card.pileMax)
      --print("card value: " .. card.value)
      card.pileIndex = card.pile:findCard(card.value, card.suit)--#card.pile.cards - ( - 1) --This is definitely a little awkward, but I can't put this in card:update as I would need to require pile.lua in card for that, and that would cause an error.
      --edit: changed to make pileIndex be the inverse of the actual index. I could change the way I order piles (currently it's newest card is 1, oldest card is last, I could do the opposite) but I don't want to go in and change everywhere I used the current method for fear of breaking something (and also it would be more work, I will not discount that as a reason). I've gotten a crash once but not any since - I'm not sure why it crashed (the error was "attempted to perform arithmetic on a nil value", so I imagine card.pile:findCard returned a non-number value or something) and I can't replicate it, soooo...hopefully that doesn't happen again I guess?
      --print("card pileIndex: ".. card.pileIndex)
      if _ > 23 then
        test = "test" .. card.pileIndex
      end
    end
  end
  
  --print("checking for mouseovers")
  checkForMouseMoving()
  --print("checked for mouseovers")
  
--  if love.mouse.isDown(1) and grabber.grabPos == nil then
    
--  end
end

function love.draw()
  --print("drawing")
  for _, pile in ipairs(mainPilesTable) do
    pile:draw()
  end
  for _, pile in ipairs(acePilesTable) do
    pile:draw()
  end
  mainDeck:draw()
  drawPile:draw()
  
  --print(#cardTable)
  for _, card in ipairs(cardTable) do
    if card.state == 2 and cardTable[1] ~= card then --if card state is GRABBED
      --print("adding grabbed cards to grabbedCardsTable")
      table.insert(grabbedCardsTable, card)
      --temp = cardTable[1] --swap it with the card at beginning of cardTable - huh, why is this not having an issue where the previous 1 card "changes layer"? So far it seems to be fine but I expected the card in index 1 to suddenly move below a card it was above when you picked up another card
      --table.insert(cardTable, 1, card)
      --table.insert(cardTable, _, temp)
    end
  end
  for i = #cardTable, 1, -1 do --Next task: currently if there are multiple cards under the cursor (like in a pile) then the card picked up will be the card earliest in cardTable, which will be the card on the bottom of the pile as it's the one that was drawn (as in love.draw, not card draw) earliest. I think if I just reverse the order of drawing cards, then it will work out, as the card on top (the last card to be drawn in the pile) will be card that is earliest in cardTable
    --edit: this worked only partially, as it only addressed the rendering of the initial deck - the cards still didn't change "layer" when they were dragged and dropped (so, e.g., dragging the card that's in index 10 in the table onto the card in index 8 will always draw the card in index 10 underneath the card in 8). To address this, I did the above for loop which changes the index when you grab a card to be index 1, which is drawn last.
    cardTable[i]:draw()
  end
  
  for _, card in ipairs(grabbedCardsTable) do --draw the cards that are in grabbedCardsTable after the rest of the cards so they're on top
    card:draw()
  end
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Mouse: " .. tostring(grabber.currentMousePos.x) .. "," .. tostring(grabber.currentMousePos.y))
end

--mouse click function:
function love.mousepressed(x, y, button, istouch)
  print("clicking")
  --print("mainDeck top card suit: "..mainDeck.cards[1][2])
  if grabber.mousedOverPile ~= nil and grabber.mousedOverPile == mainDeck:checkForMouseOver(grabber) then --need the nil check or otherwise this happens when you aren't moused over the pile, since at that point both mainDeck:checkForMouseover and mousedOverPile would be nil, and so would be the same
    --print(grabber.mousedOverPile)
    if #mainDeck.cards <= 0 then -- don't do anything if there aren't any cards remaining in the deck (placeholder, change to put remaining cards back in deck eventually)
      printPile(drawPile)
      print("cards in drawPile: " .. #drawPile.cards)
      resetDeck(mainDeck, drawPile)
      return
    else
      print("draw 3 cards")
      for i = 1, 3 do
        print(#mainDeck.cards)
        print("mainDeck top card suit: "..mainDeck.cards[1].suit)
        --print(mainDeck.top[2])
        --print(cardTable[matchCard(cardTable, mainDeck.top[1], mainDeck.top[2])])
        topCard = cardTable[matchCard(cardTable, mainDeck.cards[1].value, mainDeck.cards[1].suit)]
        topCard.position = drawPile.position
        topCard.faceDown = false
        --print(topCard.suit)
        drawPile:push(topCard)
        topCard.inPile = true
        topCard.pile = drawPile
        table.remove(mainDeck.cards, 1)--pop()
        --print(mainDeck.cards[1][2])
        mainDeck.top = mainDeck.cards[1]
      end
    end
  end
end

function checkForMouseMoving()
  if grabber.currentMousePos == nil then
    return
  end
  
  for _, card in ipairs(cardTable) do
    --print(card)
    --print("mouseover check for cards")
    grabber.mousedOverCard = card:checkForMouseOver(grabber)
    if grabber.mousedOverCard ~= nil then
      break --sweet, this fixed the problem of only being able to pick up the last created card (without this, I think mousedOverCard will always be set to the moused over status of the last card in the table. Hopefully this doesn't cause other problems 

    end
    --print(grabber.mousedOverObject)
    
  end
  
  for _, pile in ipairs(mainPilesTable) do --oh no, other problems! for multiple tables of piles, only the last table is being checked, or the last pile if mainDeck is last - that is, if the code as written checks every pile in mainPilesTable, then every pile in acePilesTable, then the mainDeck pile, only the main deck pile will actually be checked and the others will be ignored
    --I think this is basically a larger version of the previous problem - even if mousedOverPile is set to a pile in (e.g.) the mainPilesTable for loop, it will then be set to nil in the following acePilesTable for loop. Therefore...
    --print(card)
    --print(pile.position.y)
    --print("mouseover check for main piles")
    grabber.mousedOverPile = pile:checkForMouseOver(grabber)
    if grabber.mousedOverPile ~= nil then 
      --print(grabber.mousedOverPile)
      break
    end
--    grabber.mousedOverByCardPile = pile:checkForCardOver(grabber)
--    if grabber.mousedOverByCardPile ~= nil then
--      break
--    end
  end
  --...I can fix it with a similar solution! Can't do a break because we don't want to break out of the update loop, but simply checking to see if mousedOverPile is still nil after each loop (and only checking the next category of piles if it is) should work, I think
  if grabber.mousedOverPile == nil then
    for _, pile in ipairs(acePilesTable) do
      grabber.mousedOverPile = pile:checkForMouseOver(grabber)
      if grabber.mousedOverPile ~= nil then 
        print("mousing over over ace pile")
        break
      end
    end
  end
  if grabber.mousedOverPile == nil then
    --print("mouseover check for deck") 
    grabber.mousedOverPile = mainDeck:checkForMouseOver(grabber)
  end
  if grabber.mousedOverPile == nil then
    --print("mouseover check for drawn cards pile")
    grabber.mousedOverPile = drawPile:checkForMouseOver(grabber)
  end
  --print(grabber.mousedOverPile)
end

function matchCard(cTable, value, suit)
  for _, card in ipairs(cTable) do
    if card.value == value and card.suit == suit then
      return _
    end
  end
  return nil
end

function shuffle(targetTable)
  math.randomseed(os.time())
  for i = 1, math.random(#targetTable - 1) do --1000
    firstIndex = i--math.random(#targetTable)
    secondIndex = math.random(#targetTable)
    swap(targetTable, firstIndex, secondIndex)
  end
end

function swap(targetTable, a, b)
  temp = targetTable[a]
  targetTable[a] = targetTable[b]
  targetTable[b] = temp
  --table.insert(targetTable, a, targetTable[b]) --the problem with shuffle was that this was using insert instead of just directly setting the elements
  --table.insert(targetTable, b, temp)
end

function shiftElements(targetTable, firstIndex, lastIndex)
  for i = lastIndex, firstIndex -1 do
    table.insert(targetTable, i+1, targetTable[i]) --shift all elements in the provided range 1 towards the end
  end
  targetTable[firstIndex] = nil --set the previous first element to nil
end

function resetDeck(deck, drawPile)
  print(#drawPile.cards)
  for _, card in ipairs(drawPile.cards) do --only doing 12?
    print(_)
    print("resetting deck")
    deck:push(card) --e.g. 10 cards in draw pile, card at [10] would go to position 1, card at [9] would go to position 2, etc.
    table.remove(drawPile.cards, _)
    --print(deck[#drawPile - _ + 1].value)
  end
end