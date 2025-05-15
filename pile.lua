--stuff to do:
--cascading piles
--shuffle deck at start
--suits displayed on cards in somne way
--correctly order cards over and under each other - done!

require "card"

PileClass = {}

pileBaseHeight = 80

function PileClass:new(xPos, yPos, cascades, type)
  local pile = {}
  local metadata = {__index = PileClass}
  setmetatable(pile, metadata)
  
  pile.cascade = cascades
  pile.type = type
  
  pile.position = Vector(xPos, yPos)
  if pile.cascade == false then
    pile.size = Vector(60, pileBaseHeight)
  else
    pile.size = Vector(60, pileBaseHeight*5)
  end
  
  pile.cards = {} --huh, this worked as self.cards when I wasn't trying to access .cards from main, but when I did it threw an error which changing it to pile.cards fixed. Why did it work partially before?
  pile.top = nil
  
  return pile
end

function PileClass:draw()
  love.graphics.setColor(0.2, 0.2, 0.2, 1)
  local xOffset = self.size.x/2
  local yOffset = self.size.y/2
  if self.cascade == true then
    love.graphics.rectangle("line", self.position.x - xOffset, self.position.y - yOffset/5, self.size.x, self.size.y*2, 6, 6)
  else
    love.graphics.rectangle("line", self.position.x - xOffset, self.position.y - yOffset, self.size.x, self.size.y, 6, 6)
  end
end

function PileClass:push(addedCard)
  table.insert(self.cards, 1, addedCard) --insert a new card at the top of the table
  self.top = addedCard
end

function PileClass:pop()
  table.remove(self.cards, 1)
  self.top = self.cards[1]
end

function PileClass:findCard(value, suit)
  for _, card in ipairs(self.cards) do
    if card.value == value and card.suit == suit then
      return _
    end
  end
  return nil --the search loop was only getting to index 1, because I had "else: return nil" after the if statement - so if index 1 wasn't the right card, the function would end there. I need to have the return nil part here, after the loop has finished and it hasn't found anything
end

function PileClass:checkForMouseOver(grabber)
  local mousePos = grabber.currentMousePos --local vs not using local?
  local isMouseOver = 
    mousePos.x > self.position.x - self.size.x/2 and
    mousePos.x < self.position.x + self.size.x/2 and
    mousePos.y > self.position.y - pileBaseHeight and
    --pileBaseHeight to account for the twe possible sizes of the piles
    mousePos.y < self.position.y + self.size.y/2
  
  if isMouseOver then
    return self
  else
    return nil
  end
end

function PileClass:checkForCardOver(grabber)
  local mousePos = grabber.currentMousePos --local vs not using local?
  local isCardOver = 
    (mousePos.x + cardWidth/2 > self.position.x - self.size.x/2 and mousePos.x + cardWidth/2 < self.position.x + self.size.x/2 and mousePos.y - cardLength/2 > self.position.y - self.size.y/2 and mousePos.y - cardLength/2 < self.position.y + self.size.y/2) or --top right corner is within pile
    (mousePos.x - cardWidth/2 > self.position.x - self.size.x/2 and mousePos.x - cardWidth/2 < self.position.x + self.size.x/2 and mousePos.y + cardLength/2 > self.position.y - self.size.y/2 and mousePos.y + cardLength/2 < self.position.y + self.size.y/2) --bottom left corner is within pile
  
  if isCardOver then
    return self
  else
    return nil
  end
end