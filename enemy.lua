-- January2013
-- Copyright © 2013 John Watson <john@watson-net.com>

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

Enemy = Sprite:extend{
    STATE_IDLE = 1,
    STATE_HOMING = 2,
    MAX_SPEED = 40,
    THRUST = 30,
    DETECTION_DISTANCE = arena.width/8,
    THRUST_INTERVAL = 2, -- seconds
    elapsed = 0,
    radius = 5,
    width = 5,
    height = 5,
    alpha = 0,

    onNew = function(self)
        self.scan_snd = love.audio.newSource("snd/scanning.ogg", "static")
        self.detected_snd = love.audio.newSource("snd/detected.ogg", "static")

        self.x = math.random(50, arena.width-50)
        if self.x > player.x - self.DETECTION_DISTANCE and self.x < player.x + self.DETECTION_DISTANCE then
            self.y = math.random(50, player.y - self.DETECTION_DISTANCE)
        else
            self.y = math.random(50, arena.height-50)
        end
        self.minVelocity = { x = -self.MAX_SPEED, y = -self.MAX_SPEED }
        self.maxVelocity = { x = self.MAX_SPEED, y = self.MAX_SPEED }
        self.drag = { x = self.THRUST, y = self.THRUST }
        self.offset = math.random()*10
        self.state = self.STATE_IDLE
        the.view.tween:start(self, 'alpha', 1, 0.75)

        the.app:add(self)
    end,

    onDraw = function(self, x, y)
        love.graphics.push()

        love.graphics.translate(x, y)
        love.graphics.rotate(math.sin(love.timer.getMicroTime())*math.pi)

        -- Detection radius
        if self.state == self.STATE_IDLE then
        else
            -- The 115 animation
            love.graphics.setColor(255, 0, 0, math.random(0, 200))
            love.graphics.circle("line", 0, 0, self.DETECTION_DISTANCE, 20)
            love.graphics.setFont(the.app.small_font)
            local visualizer = math.sin(love.timer.getTime())
            local characters = { "1", "1", "5", }
            if visualizer >= 0 then
                for i = 1,10 do
                    for j = 1,3 do
                        local a = math.random() * math.pi*2;
                        local c = characters[math.random(1,#characters)]
                        local r = 30 + 10 * j
                        local x1 = math.cos(a) * r
                        local y1 = math.sin(a) * r
                        love.graphics.print(c, x1, y1, a)
                    end
                end
            end
            if visualizer < 0 then
                for i = 1,10 do
                    for j = 1,#characters do
                        local a = math.pi*2/10 * i;
                        local c = characters[j]
                        local r = 30 + 10 * j
                        local x1 = math.cos(a) * r
                        local y1 = math.sin(a) * r
                        love.graphics.print(c, x1, y1, a)
                    end
                end
            end
        end

        -- Scanner circles animation
        love.graphics.setColor(255, 0, 0, self.alpha * 50)
        love.graphics.circle("line", 0, 0, self.DETECTION_DISTANCE * math.sin(love.timer.getMicroTime()*3+self.offset), 20)
        love.graphics.circle("line", 0, 0, self.DETECTION_DISTANCE * math.sin(love.timer.getMicroTime()*18+self.offset), 20)
        love.graphics.circle("line", 0, 0, self.DETECTION_DISTANCE * math.sin(love.timer.getMicroTime()*32+self.offset), 20)

        -- The ship
        love.graphics.setColor(255, 0, 0, self.alpha * 255)
        love.graphics.circle("line", 0, 0, self.radius, 3)

        love.graphics.pop()
    end,

    onUpdate = function(self, dt)
        if player.state == player.STATE_ALIVE then
            self:collide(player)
        end

        self.elapsed = self.elapsed + dt

        local distance = self:distanceTo(player)

        if player.state == player.STATE_ALIVE and distance <= self.DETECTION_DISTANCE then
            if self.detected_snd:isStopped() then
                love.audio.play(self.detected_snd)
            end

            self.state = self.STATE_HOMING

            -- Calculate vector to player and GO
            local dx = player.x - self.x
            local dy = player.y - self.y
            local n = math.max(math.abs(dx), math.abs(dy))

            -- Accelerate towards the player. Increase acceleration the closer we get.
            -- If the acceleration doesn't change as we approach, then the acceleration
            -- acts just like gravity and allows the enemies to orbit the player.
            self.acceleration.x = dx/n * self.THRUST * self.DETECTION_DISTANCE/distance
            self.acceleration.y = dy/n * self.THRUST * self.DETECTION_DISTANCE/distance
        else
            self.state = self.STATE_IDLE

            if not self.detected_snd:isStopped() then
                self.detected_snd:stop()
            end

            if math.random(0,6000) <= 1 then
                if self.scan_snd:isStopped() then
                    love.audio.play(self.scan_snd)
                end
            end

            if self.elapsed > self.THRUST_INTERVAL then
                self.acceleration.x = math.random(-self.THRUST/5, self.THRUST/5)
                self.acceleration.y = math.random(-self.THRUST/5, self.THRUST/5)
                self.elapsed = 0
            end
        end

        if self.x < self.radius then
            self.x = self.radius
            self.velocity.x = -self.velocity.x
        end
        if self.x > arena.width - self.radius then
            self.x = arena.width - self.radius
            self.velocity.x = -self.velocity.x
        end
        if self.y < self.radius then
            self.y = self.radius
            self.velocity.y = -self.velocity.y
        end
        if self.y > arena.height - self.radius then
            self.y = arena.height - self.radius
            self.velocity.y = -self.velocity.y
        end
    end,

    onCollide = function(self, other, overlap_x, overlap_y)
        player:explode()
        self:die()
    end,

    collide = function(self, other)
        if self:distanceTo(other) <= self.radius + other.radius then
            if self.onCollide then
                self:onCollide(other, 0, 0)
            end
            
            if other.onCollide then
                other:onCollide(self, 0, 0)
            end

            return true
        end
        return false
    end,
}