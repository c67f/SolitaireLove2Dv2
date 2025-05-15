require "vector"
require "pile"
require "card"

GrabberClass = {}

function GrabberClass:new()
  local grabber = {}
  local metadata = {__index = GrabberClass}
  setmetatable(grabber, metadata)
  
    
  grabber.currentMousePos = nil
  grabber.previousMousePos = nil
  
  grabber.grabPos = nil
  grabber.grabPile = nil --the pile that the held card was grabbed from
  
  grabber.mousedOverCard = nil
  grabber.heldObjects = {} --table of all the cards being grabbed
  
  grabber.mousedOverPile = nil
  grabber.mousedOverByCardPile = nil --adding this because otherwise there is an error related to grabbing a card that is overlapping a pile while mousing over that pile, but the card itself is not part of the pile. This can't happen if a card, when dropped, is added to a pile if the card is overlapping the pile at all (rather than the mouse being over the pile), so this is part of that.
  grabber.grabbing = false
  
  return grabber
end


function GrabberClass:update()
  self.currentMousePos = Vector(
    love.mouse.getX(),
    love.mouse.getY()
  )
  
  --Click
  if love.mouse.isDown(1) and self.grabPos == nil then
    self:grab()
  end
  --Release
  if not love.mouse.isDown(1) and self.grabPos ~= nil then
    self:release()
  end
end

--function GrabberClass:checkForMouseOver(object) --moving checkForMouseOver to grabber.lua now that I want to check for more than just cards, so i only have to write it once in grabber rather than multiple times, once for each object type (e.g. card and pile)
  
--  local mousePos = self.currentMousePos --local vs not using local?
--  local isMouseOver = 
--    mousePos.x > object.position.x and
--    mousePos.x < object.position.x + object.size.x and
--    mousePos.y > object.position.y and
--    mousePos.y < object.position.y + object.size.y
  
--  --self.state = isMouseOver and CARD_STATE.MOUSE_OVER or CARD_STATE.IDLE --hmm might still need mouseover checking in card.lua to change its state since I'm not sure how to check what type an object is
--  if isMouseOver then
--    return object
--  end
--end
--hm maybe can't do this because I don't know how to get the specific card that's below the grabber - the version in card.lua works becuase it's getting the position of grabber, and there's only ever one grabber


function GrabberClass:grab()
  --print("grabbing")
  if self.mousedOverCard == nil or self.mousedOverCard.faceDown == true then --can't grab face down cards, that way you can't grab from the deck
    if self.mousedOverCard ~= nil and self.mousedOverCard.faceDown == true then
      print("moused over face down card")
    end
    return
  end
  if self.mousedOverPile ~= nil then --if grabbing a card while over a pile, remove that card from that pile
    print(self.mousedOverPile)
    self.grabPos = self.currentMousePos
    print("held object: "..self.mousedOverCard.value)
    index = self.mousedOverPile:findCard(self.mousedOverCard.value, self.mousedOverCard.suit)
    if index ~= 1 then --if the moused over card is not the top card
      for i = 1, 1, index-1 do
        if self.mousedOverPile.cards[i].faceDown == false then --insert the cards on top of the picked up card into the heldObjects table
          print("removed card is " .. self.mousedOverPile.cards[i].value)
          table.insert(self.heldObjects, i, self.mousedOverPile.cards[i])
          table.remove(self.mousedOverPile.cards, 1) --remove top card - don't need to set specific index to remove as it will always be 1
          print("i is " .. i)
        end
      end
    end
    print("index is " .. index)
    table.insert(self.heldObjects, self.mousedOverCard) --then insert the picked up card as the last element in the table
    table.remove(self.mousedOverPile.cards, 1)
    
    self.grabPos = self.mousedOverPile.position --sets grabPos to be the pile's position if the card was grabbed from a pile
    self.grabPile = self.mousedOverPile
    


    --self.mousedOverPile:pop()
    --self.mousedOverPile.size.y = self.mousedOverPile.size.y - 20
    if #self.mousedOverPile.cards > 0 then --check if pile is now empty
      self.mousedOverPile.top = self.mousedOverPile.cards[1]
      print("new top value after picking up is " .. self.mousedOverPile.top.value)
      printPile(self.mousedOverPile)
    else
      print("pile empty")
    end
    
    for _, card in ipairs(self.heldObjects) do
      card.inPile = false
      card.pile = nil
      card.state = 2 --GRABBED
    end
    
    --print(#self.mousedOverPile.cards)
    print("GRAB - " .. tostring(self.grabPos.x))
    self.grabbing = true
  end
  --print("grabbed object: " .. self.heldObject)
end

function GrabberClass:release()
  print("RELEASE -")
  
  if #self.heldObjects == 0 then
    return
  end
  
  --print("dropping card on table with top card" .. self.mousedOverPile.top.value .. " of " .. self.mousedOverPile.top.suit)
  local isValidReleasePosition = checkIfValidPos(self.heldObjects[#self.heldObjects], self.mousedOverPile) --check if the starting card in the pile (the card with the lowest value) can be legally dropped onto the pile
  
  if not isValidReleasePosition then
    for _, card in ipairs(self.heldObjects) do
      self.grabPile:push(card)
      card.pile = self.grabPile
      card.inPile = true
    end
  else
    for _, card in ipairs(self.heldObjects) do
      self.mousedOverPile:push(card)
      card.pile = self.mousedOverPile
      card.inPile = true
    end
    
    if self.mousedOverPile.cascade == false then
      print("dropping cards on non-cascading pile")
      --print(self.heldObject.value)
      printPile(self.mousedOverPile)
      for _, card in ipairs(self.heldObjects) do
        card.position = self.mousedOverPile.position-- + 40
      end
    else
      printPile(self.mousedOverPile)
      print("dropping cards on cascading pile")
      print(#self.mousedOverPile.cards)
    end
  end

  
  for _, card in ipairs(self.heldObjects) do
    card.state = 0
  end
  
  self.heldObjects = {}
  self.grabPos = nil
  self.grabbing = false
end

function checkIfValidPos(card, pile)
  if pile == nil then --if the card is not dropped on a pile, put it back where you picked it up from
    print("invalid drop location - no pile at this location")
    return false
  end
  --print("top card of pile is a " .. pile.top.value .. " of " .. pile.top.suit)
  print("held card is a " .. card.value .. " of " .. card.suit)
  if pile.top ~= nil then
    --print("pile exists")
    --print(pile.top.value)
    if pile.top.value  == (card.value + 1) and oppositeColor(pile.top.suit, card.suit) then
      --print(card.value)
      --print(pile.top.value)
      print("putting " .. card.value .. " on " .. pile.top.value)
      return true
    end
  elseif pile.top == nil and (pile.type == "ace" and card.value == 1) or (pile.type == "tableau"  and card.value == 13) then --if pile is an ace pile and the held card is an ace, or if it's an empty tableau pile and the held card is a king
    return true
  else
    print("invalid drop location - solitaire rules")
    return false
  end
end

function oppositeColor(suit1, suit2)
  if suit1 == "d" or suit1 == "h" then
    if suit2 == "c" or suit2 == "s" then
     return true
    else
      return false
    end
  else
    if suit2 == "d" or suit2 == "h" then
      return true
    else
      return false
    end
  end
end

function printPile(pile)
  print ("pile:")
  for _, card in ipairs(pile.cards) do
    print(card.value .. ", " .. card.suit)
  end
end