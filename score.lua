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

score = {
    level_total = 0, -- Fuel collected this level
    level_graph = {}, -- Graph of fuel collected/second this level
    game_total = 0, -- Fuel collected this game
    game_score = 0, -- Game score

    startGame = function(self)
        self.game_total = 0
        self.game_score = 0
        self:startLevel()
    end,

    startLevel = function(self)
        self.level_total = 0
        self.level_graph = {}
        self.start_time = os.time()
    end,

    add = function(self, fuel)
        local index = os.time() - self.start_time + 1

        self.level_total = self.level_total + fuel
        self.game_total = self.game_total + fuel
        self.game_score = self.game_score + fuel * the.app.level * 100

        while true do
            if self.level_graph[index] then
                self.level_graph[index] = self.level_graph[index] + fuel
                break
            else
                table.insert(self.level_graph, 0)
            end
        end
    end,

    getFuelPerMinute = function(self)
        local min = (os.time() - self.start_time) / 60
        local fpm = self.level_total / min
        if min == 0 then fpm = 0 end
        -- fpm = math.ceil(fpm*100)/100
        fpm = math.floor(fpm)
        return fpm
    end,

    getFuel = function(self)
        return math.floor(self.level_total) or 0
    end,

    getTotalFuel = function(self)
        return math.floor(self.game_total) or 0
    end,

    getScore = function(self)
        return math.floor(self.game_score) or 0
    end,

    update = function(self)
        self:add(0)
    end
}