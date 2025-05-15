require "vector"
--require "grabber"

CardClass = {}


CARD_STATE = {
  IDLE = 0,
  MOUSE_OVER = 1,
  GRABBED = 2
}

cardWidth = 50
cardLength = 70


function CardClass:new(xPos, yPos, value, suit)  --constructor
  local card = {}
  local metatable = {__index = CardClass}
  setmetatable(card, metatable)
  
  card.position = Vector(xPos, yPos)
  card.size = Vector(cardWidth, cardLength)
  card.state = CARD_STATE.IDLE
  card.value = value--math.random(#CARD_VALUE) --# gets how many elements are in the following thing
  card.suit = suit
  card.faceDown = false
  
  card.inPile = false
  card.pile = nil
  card.pileIndex = nil
  card.pileMax = nil
  
  
  --card.pileX = 0
  --card.pileY = 0
  
  return card
end

function CardClass:update(grabber) --added grabber as argument
  --if grabber.heldObjects[1] == self and self.inPile == false and self.state ~= CARD_STATE.GRABBED then --added check for if self.inPile to hopefully allow the card to move when first grabbed
    --self.state = CARD_STATE.GRABBED
  --end
  if self.state == CARD_STATE.GRABBED then
    --print("grabbed")
    self.position = grabber.currentMousePos
  end
  
  if self.inPile == true and self.pile.cascade == true and self.pileIndex ~= nil then
    --print("moving card to cascade")
    --print("suit: "..self.suit)
    --print("pileX: "..self.pileX)
    self.position.x = self.pile.position.x
    self.position.y = self.pile.position.y + (20 * (self.pileMax - (self.pileIndex)))
    --print("card offset from pile top: " .. self.pileMax - (self.pileIndex))
    --??? What is happening???
    
    if self.pileIndex == 1 then --self.pileMax
      self.faceDown = false
--    else
--      self.faceDown = true
    end
  end
  if self.inPile == true and self.pile.cascade == false then
    self.position = self.pile.position
  end
end

function CardClass:draw()
  --print("drawing card (as in art, not as in taking a card from a deck)")
  local xOffset = self.size.x/2
  local yOffset = self.size.y/2
  if self.faceDown == true then
    love.graphics.setColor(0, 0, 0.4, 1)
    love.graphics.rectangle("fill", self.position.x - xOffset, self.position.y - yOffset, self.size.x, self.size.y, 6, 6)
  else
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.position.x - xOffset, self.position.y - yOffset, self.size.x, self.size.y, 6, 6)
    if self.state ~= CARD_STATE.IDLE then
      love.graphics.setColor(0, 0, 0, 0.8)
      local xOffset = 4 * (self.state == CARD_STATE.GRABBED and 2 or 1) - self.size.x/2
      local yOffset = 4 * (self.state == CARD_STATE.GRABBED and 2 or 1) - self.size.y/2
      love.graphics.rectangle("fill", self.position.x + xOffset, self.position.y + yOffset, self.size.x, self.size.y, 6, 6) --shadow
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", self.position.x - xOffset, self.position.y - yOffset, self.size.x, self.size.y, 6, 6)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.position.x - xOffset, self.position.y - yOffset, self.size.x, self.size.y, 6, 6)
    --print(self.value)
    
    love.graphics.print(self.value, self.position.x - xOffset, self.position.y - yOffset)
    love.graphics.print(self.suit, self.position.x, self.position.y)
  end
end

function CardClass:checkForMouseOver(grabber)
  --print("checking for mouseover in CardClass")
  if self.state == CARD_STATE.GRABBED or self.faceDown == true then
    return nil --forgot to put nil here - does that make a difference?
  end
  
  local mousePos = grabber.currentMousePos --local vs not using local?
  local isMouseOver = 
    mousePos.x > self.position.x - self.size.x/2 and
    mousePos.x < self.position.x + self.size.x/2 and
    mousePos.y > self.position.y - self.size.y/2 and
    mousePos.y < self.position.y + self.size.y/2
  
  self.state = isMouseOver and CARD_STATE.MOUSE_OVER or CARD_STATE.IDLE
  if isMouseOver then
    return self
  else
    return nil
  end
end