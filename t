[1mdiff --git a/test/events.jl b/test/events.jl[m
[1mindex dcacf246..1501ceb6 100644[m
[1m--- a/test/events.jl[m
[1m+++ b/test/events.jl[m
[36m@@ -10,22 +10,22 @@[m [mBase.:(==)(l::Or, r::Or) = l.left == r.left && l.right == r.right[m
 @testset "PriorityObservable" begin[m
     po = PriorityObservable(0)[m
 [m
[31m-    first = Observable(0.0)[m
[31m-    second = Observable(0.0)[m
[31m-    third = Observable(0.0)[m
[32m+[m[32m    first = Observable(UInt64(0))[m
[32m+[m[32m    second = Observable(UInt64(0))[m
[32m+[m[32m    third = Observable(UInt64(0))[m
 [m
     on(po, priority=1) do x[m
         sleep(0)[m
[31m-        first[] = time()[m
[32m+[m[32m        first[] = time_ns()[m
     end[m
     on(po, priority=0) do x[m
         sleep(0)[m
[31m-        second[] = time()[m
[32m+[m[32m        second[] = time_ns()[m
         return Consume(isodd(x))[m
     end[m
     on(po, priority=-1) do x[m
         sleep(0)[m
[31m-        third[] = time()[m
[32m+[m[32m        third[] = time_ns()[m
         return Consume(false)[m
     end[m
 [m
