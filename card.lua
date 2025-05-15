require "vector"

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
  card.value = value
  card.suit = suit
  card.faceDown = false
  
  card.inPile = false
  card.pile = nil
  card.pileIndex = nil
  card.pileMax = nil
  
  return card
end

function CardClass:update(grabber)
  if self.state == CARD_STATE.GRABBED then
    self.position = grabber.currentMousePos
  end
  
  if self.inPile == true and self.pile.cascade == true and self.pileIndex ~= nil then
    self.position.x = self.pile.position.x
    self.position.y = self.pile.position.y + (20 * (self.pileMax - (self.pileIndex)))
    
    if self.pileIndex == 1 then
      self.faceDown = false
    end
  end
  if self.inPile == true and self.pile.cascade == false then
    self.position = self.pile.position
  end
end

function CardClass:draw()
  local xOffset = self.size.x/2
  local yOffset = self.size.y/2
  if self.faceDown == true then
    --set the card to just be solid blue if face down
    love.graphics.setColor(0, 0, 0.4, 1)
    love.graphics.rectangle("fill", self.position.x - xOffset, self.position.y - yOffset, self.size.x, self.size.y, 6, 6)
  else
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.position.x - xOffset, self.position.y - yOffset, self.size.x, self.size.y, 6, 6)
    if self.state ~= CARD_STATE.IDLE then
       --draw a drop shadow if the card is being picked up or moused over
      love.graphics.setColor(0, 0, 0, 0.8)
      local xOffset = 4 * (self.state == CARD_STATE.GRABBED and 2 or 1) - self.size.x/2
      local yOffset = 4 * (self.state == CARD_STATE.GRABBED and 2 or 1) - self.size.y/2
      love.graphics.rectangle("fill", self.position.x + xOffset, self.position.y + yOffset, self.size.x, self.size.y, 6, 6)
    end
    --background of card
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", self.position.x - xOffset, self.position.y - yOffset, self.size.x, self.size.y, 6, 6)
    
    --outline of card
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.position.x - xOffset, self.position.y - yOffset, self.size.x, self.size.y, 6, 6)
    
    --print value and suit on card
    love.graphics.print(self.value, self.position.x - xOffset, self.position.y - yOffset)
    love.graphics.print(self.suit, self.position.x, self.position.y)
  end
end

function CardClass:checkForMouseOver(grabber)
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