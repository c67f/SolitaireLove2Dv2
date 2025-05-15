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
      table.insert(cardTable, CardClass:new(mainDeck.position.x, mainDeck.position.y, value, suit))
    end
  end
  shuffle(cardTable)

  for i = 1, 24 do
    mainDeck:push(cardTable[i])
    cardTable[i].faceDown = true
  end
  
  for i = 1, 7 do
    table.insert(mainPilesTable, PileClass:new(150 + (i-1) * 70, 170, true, "tableau"))
  end
  
  mainCardCount = 52
  for i = 1, 7 do
    for j = 1, i do
      mainPilesTable[i]:push(cardTable[mainCardCount])
      cardTable[mainCardCount].pile = mainPilesTable[i]
      cardTable[mainCardCount].inPile = true
      cardTable[mainCardCount].faceDown = true --set all but the last card in each pile to be face down
      mainCardCount = mainCardCount - 1
    end
  end
  
  for i = 1, 4 do
    table.insert(acePilesTable, PileClass:new(160 + (i-1)*70, 70, false, "ace"))
  end

end

function love.update()
  grabber:update()

  for _, card in ipairs(cardTable) do --key is _, value is entity (don't care about the key, but ipairs(entity table) returns two things so we need a place to store the first (the key)
    card:update(grabber)
    if card.inPile == true and grabber.grabbing == false then --don't update while moving a card, so that the face down code in card.lua works properly
      card.pileMax = #card.pile.cards
      card.pileIndex = card.pile:findCard(card.value, card.suit)--#card.pile.cards - ( - 1) --This is definitely a little awkward, but I can't put this in card:update as I would need to require pile.lua in card for that, and that would cause an error.
      --edit: changed to make pileIndex be the inverse of the actual index. I could change the way I order piles (currently it's newest card is 1, oldest card is last, I could do the opposite) but I don't want to go in and change everywhere I used the current method for fear of breaking something (and also it would be more work, I will not discount that as a reason). I've gotten a crash once but not any since - I'm not sure why it crashed (the error was "attempted to perform arithmetic on a nil value", so I imagine card.pile:findCard returned a non-number value or something) and I can't replicate it, soooo...hopefully that doesn't happen again I guess?
      if _ > 23 then
        test = "test" .. card.pileIndex
      end
    end
  end
  
  checkForMouseMoving()
end

function love.draw()
  for _, pile in ipairs(mainPilesTable) do
    pile:draw()
  end
  for _, pile in ipairs(acePilesTable) do
    pile:draw()
  end
  mainDeck:draw()
  drawPile:draw()
  
  for _, card in ipairs(cardTable) do
    if card.state == 2 and cardTable[1] ~= card then --if card state is GRABBED
      table.insert(grabbedCardsTable, card)
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
end

function love.mousepressed(x, y, button, istouch)
  if grabber.mousedOverPile ~= nil and grabber.mousedOverPile == mainDeck:checkForMouseOver(grabber) then --need the nil check or otherwise this happens when you aren't moused over the pile, since at that point both mainDeck:checkForMouseover and mousedOverPile would be nil, and so would be the same
    if #mainDeck.cards <= 0 then
      resetDeck(mainDeck, drawPile)
      return
    else
      for i = 1, 3 do
        topCard = cardTable[matchCard(cardTable, mainDeck.cards[1].value, mainDeck.cards[1].suit)]
        topCard.position = drawPile.position
        topCard.faceDown = false
        drawPile:push(topCard)
        topCard.inPile = true
        topCard.pile = drawPile
        table.remove(mainDeck.cards, 1)
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
    grabber.mousedOverCard = card:checkForMouseOver(grabber)
    if grabber.mousedOverCard ~= nil then
      break --sweet, this fixed the problem of only being able to pick up the last created card (without this, I think mousedOverCard will always be set to the moused over status of the last card in the table. Hopefully this doesn't cause other problems 

    end
    
  end
  
  for _, pile in ipairs(mainPilesTable) do --oh no, other problems! for multiple tables of piles, only the last table is being checked, or the last pile if mainDeck is last - that is, if the code as written checks every pile in mainPilesTable, then every pile in acePilesTable, then the mainDeck pile, only the main deck pile will actually be checked and the others will be ignored
    --I think this is basically a larger version of the previous problem - even if mousedOverPile is set to a pile in (e.g.) the mainPilesTable for loop, it will then be set to nil in the following acePilesTable for loop. Therefore...
    grabber.mousedOverPile = pile:checkForMouseOver(grabber)
    if grabber.mousedOverPile ~= nil then 
      break
    end
  end
  --...I can fix it with a similar solution! Can't do a break because we don't want to break out of the update loop, but simply checking to see if mousedOverPile is still nil after each loop (and only checking the next category of piles if it is) should work, I think
  if grabber.mousedOverPile == nil then
    for _, pile in ipairs(acePilesTable) do
      grabber.mousedOverPile = pile:checkForMouseOver(grabber)
      if grabber.mousedOverPile ~= nil then
        break
      end
    end
  end
  if grabber.mousedOverPile == nil then
    grabber.mousedOverPile = mainDeck:checkForMouseOver(grabber)
  end
  if grabber.mousedOverPile == nil then
    grabber.mousedOverPile = drawPile:checkForMouseOver(grabber)
  end
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
end

function shiftElements(targetTable, firstIndex, lastIndex)
  for i = lastIndex, firstIndex -1 do
    table.insert(targetTable, i+1, targetTable[i]) --shift all elements in the provided range 1 towards the end
  end
  targetTable[firstIndex] = nil --set the previous first element to nil
end

function resetDeck(deck, drawPile)
  for _, card in ipairs(drawPile.cards) do --only doing 12?
    deck:push(card) --e.g. 10 cards in draw pile, card at [10] would go to position 1, card at [9] would go to position 2, etc.
    table.remove(drawPile.cards, _)
  end
end