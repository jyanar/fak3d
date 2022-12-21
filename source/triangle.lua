class('Triangle').extends()

function Triangle:init(p1, p2, p3)
    self.p1 = p1
    self.p2 = p2
    self.p3 = p3
end

function Triangle:vertices()
    return {self.p1, self.p2, self.p3}
end
