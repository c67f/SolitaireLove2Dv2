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




function GrabberClass:grab()
  if self.mousedOverCard == nil or self.mousedOverCard.faceDown == true then --can't grab face down cards, that way you can't grab from the deck
    if self.mousedOverCard ~= nil and self.mousedOverCard.faceDown == true then
    end
    return
  end
  if self.mousedOverPile ~= nil then --if grabbing a card while over a pile, remove that card from that pile
    self.grabPos = self.currentMousePos
    index = self.mousedOverPile:findCard(self.mousedOverCard.value, self.mousedOverCard.suit)
    if index ~= 1 then --if the moused over card is not the top card
      for i = 1, 1, index-1 do
        if self.mousedOverPile.cards[i].faceDown == false then --insert the cards on top of the picked up card into the heldObjects table
          table.insert(self.heldObjects, i, self.mousedOverPile.cards[i])
          table.remove(self.mousedOverPile.cards, 1) --remove top card - don't need to set specific index to remove as it will always be 1
        end
      end
    end
    table.insert(self.heldObjects, self.mousedOverCard) --then insert the picked up card as the last element in the table
    table.remove(self.mousedOverPile.cards, 1)
    
    self.grabPos = self.mousedOverPile.position --sets grabPos to be the pile's position if the card was grabbed from a pile
    self.grabPile = self.mousedOverPile
    
    if #self.mousedOverPile.cards > 0 then --check if pile is now empty
      self.mousedOverPile.top = self.mousedOverPile.cards[1]
    end
    
    for _, card in ipairs(self.heldObjects) do
      card.inPile = false
      card.pile = nil
      card.state = 2 --GRABBED
    end
    
    self.grabbing = true
  end
end

function GrabberClass:release()
  
  if #self.heldObjects == 0 then
    return
  end
  
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
      for _, card in ipairs(self.heldObjects) do
        card.position = self.mousedOverPile.position-- + 40
      end
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
    return false
  end
  if pile.top ~= nil then
    if pile.top.value  == (card.value + 1) and oppositeColor(pile.top.suit, card.suit) then
      return true
    end
  elseif pile.top == nil and (pile.type == "ace" and card.value == 1) or (pile.type == "tableau"  and card.value == 13) then --if pile is an ace pile and the held card is an ace, or if it's an empty tableau pile and the held card is a king
    return true
  else
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