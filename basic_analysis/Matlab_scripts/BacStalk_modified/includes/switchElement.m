function switchElement(src, state)
elements = src.Parent.Children;
for i = 1:numel(elements)
    elements(i).Visible = state;
end

elements = src.Parent.Parent.Children(1);
for i = 1:numel(elements)
    elements(i).Visible = state;
end