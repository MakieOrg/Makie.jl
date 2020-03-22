bottomleft(bbox::Rect2D{T}) where T = Point2{T}(left(bbox), bottom(bbox))
topleft(bbox::Rect2D{T}) where T = Point2{T}(left(bbox), top(bbox))
bottomright(bbox::Rect2D{T}) where T = Point2{T}(right(bbox), bottom(bbox))
topright(bbox::Rect2D{T}) where T = Point2{T}(right(bbox), top(bbox))

topline(bbox::BBox) = (topleft(bbox), topright(bbox))
bottomline(bbox::BBox) = (bottomleft(bbox), bottomright(bbox))
leftline(bbox::BBox) = (bottomleft(bbox), topleft(bbox))
rightline(bbox::BBox) = (bottomright(bbox), topright(bbox))
