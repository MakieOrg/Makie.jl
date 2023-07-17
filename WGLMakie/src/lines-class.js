
function get_point(array, index, ndim) {
    if (ndim === 2) {
        return new Three.Point2(array[index], array[index + 1]);
    }
}

/**
 *
 * @param vertices: Array<Point>
 * @param join: string
 * @param cap: string
 * @param miterLimit: number
 * @param roundLimit: number
 * @returns
 */
function addLine(vertices, join, cap, miterLimit, roundLimit) {

    this.distance = 0;
    this.scaledDistance = 0;
    this.totalDistance = 0;
    this.lineSoFar = 0;

    // If the line has duplicate vertices at the ends, adjust start/length to remove them.
    let len = vertices.length;

    while (len >= 2 && vertices[len - 1].equals(vertices[len - 2])) {
        len--;
    }
    let first = 0;
    while (first < len - 1 && vertices[first].equals(vertices[first + 1])) {
        first++;
    }

    // Ignore invalid geometry.
    if (len < 2) return;

    if (join === 'bevel') miterLimit = 1.05;

    const sharpCornerOffset = this.overscaling <= 16 ?
        SHARP_CORNER_OFFSET * EXTENT / (512 * this.overscaling) :
        0;

    // we could be more precise, but it would only save a negligible amount of space
    const segment = this.segments.prepareSegment(len * 10, this.layoutVertexArray, this.indexArray);

    let currentVertex;
    let prevVertex;
    let nextVertex;
    let prevNormal;
    let nextNormal;

    // the last two vertices added
    this.e1 = this.e2 = -1;
    const ndim = 2;

    for (let i = first; i < len; i++) {

        nextVertex = i === len - 1 ? undefined : get_point(vertices, i + 1, ndim); // just the next vertex

        // if two consecutive vertices exist, skip the current one
        if (nextVertex && vertices[i].equals(nextVertex)) continue;

        if (nextNormal) prevNormal = nextNormal;
        if (currentVertex) prevVertex = currentVertex;

        currentVertex = get_point(vertices, i, ndim);

        // Calculate the normal towards the next vertex in this line. In case
        // there is no next vertex, pretend that the line is continuing straight,
        // meaning that we are just using the previous normal.
        nextNormal = nextVertex ? nextVertex.sub(currentVertex)._unit()._perp() : prevNormal;

        // If we still don't have a previous normal, this is the beginning of a
        // non-closed line, so we're doing a straight "join".
        prevNormal = prevNormal || nextNormal;

        // Determine the normal of the join extrusion. It is the angle bisector
        // of the segments between the previous line and the next line.
        // In the case of 180° angles, the prev and next normals cancel each other out:
        // prevNormal + nextNormal = (0, 0), its magnitude is 0, so the unit vector would be
        // undefined. In that case, we're keeping the joinNormal at (0, 0), so that the cosHalfAngle
        // below will also become 0 and miterLength will become Infinity.
        let joinNormal = prevNormal.add(nextNormal);

        if (joinNormal.x !== 0 || joinNormal.y !== 0) {
            joinNormal._unit();
        }
        /*  joinNormal     prevNormal
            *             ↖      ↑
            *                .________. prevVertex
            *                |
            * nextNormal  ←  |  currentVertex
            *                |
            *     nextVertex !
            *
            */

        // calculate cosines of the angle (and its half) using dot product
        const cosAngle = prevNormal.x * nextNormal.x + prevNormal.y * nextNormal.y;
        const cosHalfAngle = joinNormal.x * nextNormal.x + joinNormal.y * nextNormal.y;

        // Calculate the length of the miter (the ratio of the miter to the width)
        // as the inverse of cosine of the angle between next and join normals
        const miterLength = cosHalfAngle !== 0 ? 1 / cosHalfAngle : Infinity;

        // approximate angle from cosine
        const approxAngle = 2 * Math.sqrt(2 - 2 * cosHalfAngle);

        const isSharpCorner = cosHalfAngle < COS_HALF_SHARP_CORNER && prevVertex && nextVertex;
        const lineTurnsLeft = prevNormal.x * nextNormal.y - prevNormal.y * nextNormal.x > 0;

        if (isSharpCorner && i > first) {
            const prevSegmentLength = currentVertex.dist(prevVertex);
            if (prevSegmentLength > 2 * sharpCornerOffset) {
                const newPrevVertex = currentVertex.sub(currentVertex.sub(prevVertex)._mult(sharpCornerOffset / prevSegmentLength)._round());
                this.updateDistance(prevVertex, newPrevVertex);
                this.addCurrentVertex(newPrevVertex, prevNormal, 0, 0, segment);
                prevVertex = newPrevVertex;
            }
        }

        // The join if a middle vertex, otherwise the cap.
        const middleVertex = prevVertex && nextVertex;
        let currentJoin = middleVertex ? join : isPolygon ? 'butt' : cap;

        if (middleVertex && currentJoin === 'round') {
            if (miterLength < roundLimit) {
                currentJoin = 'miter';
            } else if (miterLength <= 2) {
                currentJoin = 'fakeround';
            }
        }

        if (currentJoin === 'miter' && miterLength > miterLimit) {
            currentJoin = 'bevel';
        }

        if (currentJoin === 'bevel') {
            // The maximum extrude length is 128 / 63 = 2 times the width of the line
            // so if miterLength >= 2 we need to draw a different type of bevel here.
            if (miterLength > 2) currentJoin = 'flipbevel';

            // If the miterLength is really small and the line bevel wouldn't be visible,
            // just draw a miter join to save a triangle.
            if (miterLength < miterLimit) currentJoin = 'miter';
        }

        // Calculate how far along the line the currentVertex is
        if (prevVertex) this.updateDistance(prevVertex, currentVertex);

        if (currentJoin === 'miter') {

            joinNormal._mult(miterLength);
            this.addCurrentVertex(currentVertex, joinNormal, 0, 0, segment);

        } else if (currentJoin === 'flipbevel') {
            // miter is too big, flip the direction to make a beveled join

            if (miterLength > 100) {
                // Almost parallel lines
                joinNormal = nextNormal.mult(-1);

            } else {
                const bevelLength = miterLength * prevNormal.add(nextNormal).mag() / prevNormal.sub(nextNormal).mag();
                joinNormal._perp()._mult(bevelLength * (lineTurnsLeft ? -1 : 1));
            }
            this.addCurrentVertex(currentVertex, joinNormal, 0, 0, segment);
            this.addCurrentVertex(currentVertex, joinNormal.mult(-1), 0, 0, segment);

        } else if (currentJoin === 'bevel' || currentJoin === 'fakeround') {
            const offset = -Math.sqrt(miterLength * miterLength - 1);
            const offsetA = lineTurnsLeft ? offset : 0;
            const offsetB = lineTurnsLeft ? 0 : offset;

            // Close previous segment with a bevel
            if (prevVertex) {
                this.addCurrentVertex(currentVertex, prevNormal, offsetA, offsetB, segment);
            }

            if (currentJoin === 'fakeround') {
                // The join angle is sharp enough that a round join would be visible.
                // Bevel joins fill the gap between segments with a single pie slice triangle.
                // Create a round join by adding multiple pie slices. The join isn't actually round, but
                // it looks like it is at the sizes we render lines at.

                // pick the number of triangles for approximating round join by based on the angle between normals
                const n = Math.round((approxAngle * 180 / Math.PI) / DEG_PER_TRIANGLE);

                for (let m = 1; m < n; m++) {
                    let t = m / n;
                    if (t !== 0.5) {
                        // approximate spherical interpolation https://observablehq.com/@mourner/approximating-geometric-slerp
                        const t2 = t - 0.5;
                        const A = 1.0904 + cosAngle * (-3.2452 + cosAngle * (3.55645 - cosAngle * 1.43519));
                        const B = 0.848013 + cosAngle * (-1.06021 + cosAngle * 0.215638);
                        t = t + t * t2 * (t - 1) * (A * t2 * t2 + B);
                    }
                    const extrude = nextNormal.sub(prevNormal)._mult(t)._add(prevNormal)._unit()._mult(lineTurnsLeft ? -1 : 1);
                    this.addHalfVertex(currentVertex, extrude.x, extrude.y, false, lineTurnsLeft, 0, segment);
                }
            }

            if (nextVertex) {
                // Start next segment
                this.addCurrentVertex(currentVertex, nextNormal, -offsetA, -offsetB, segment);
            }

        } else if (currentJoin === 'butt') {
            this.addCurrentVertex(currentVertex, joinNormal, 0, 0, segment); // butt cap

        } else if (currentJoin === 'square') {
            const offset = prevVertex ? 1 : -1; // closing or starting square cap

            if (!prevVertex) {
                this.addCurrentVertex(currentVertex, joinNormal, offset, offset, segment);
            }

            // make the cap it's own quad to avoid the cap affecting the line distance
            this.addCurrentVertex(currentVertex, joinNormal, 0, 0, segment);

            if (prevVertex) {
                this.addCurrentVertex(currentVertex, joinNormal, offset, offset, segment);
            }

        } else if (currentJoin === 'round') {

            if (prevVertex) {
                // Close previous segment with butt
                this.addCurrentVertex(currentVertex, prevNormal, 0, 0, segment);

                // Add round cap or linejoin at end of segment
                this.addCurrentVertex(currentVertex, prevNormal, 1, 1, segment, true);
            }
            if (nextVertex) {
                // Add round cap before first segment
                this.addCurrentVertex(currentVertex, nextNormal, -1, -1, segment, true);

                // Start next segment with a butt
                this.addCurrentVertex(currentVertex, nextNormal, 0, 0, segment);
            }
        }

        if (isSharpCorner && i < len - 1) {
            const nextSegmentLength = currentVertex.dist(nextVertex);
            if (nextSegmentLength > 2 * sharpCornerOffset) {
                const newCurrentVertex = currentVertex.add(nextVertex.sub(currentVertex)._mult(sharpCornerOffset / nextSegmentLength)._round());
                this.updateDistance(currentVertex, newCurrentVertex);
                this.addCurrentVertex(newCurrentVertex, nextNormal, 0, 0, segment);
                currentVertex = newCurrentVertex;
            }
        }
    }
}
